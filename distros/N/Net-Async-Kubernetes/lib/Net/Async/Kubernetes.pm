package Net::Async::Kubernetes;
# ABSTRACT: Async Kubernetes client for IO::Async
our $VERSION = '0.009';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw(carp croak);
use Scalar::Util qw(blessed);
use IO::Socket::SSL;
use File::Temp ();
use Future;
use URI;
use Protocol::WebSocket::Request;
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::HTTPRequest;
use Kubernetes::REST::HTTPResponse;
use Kubernetes::REST::WatchEvent;
use Kubernetes::REST::LogEvent;
use Net::Async::Kubernetes::PortForwardSession;
use Net::Async::Kubernetes::Watcher;
use Net::Async::Kubernetes::Controller;

sub configure {
    my ($self, %params) = @_;

    if (exists $params{kubeconfig}) {
        $self->{kubeconfig} = delete $params{kubeconfig};
    }
    if (exists $params{context}) {
        $self->{context} = delete $params{context};
    }
    if (exists $params{server}) {
        my $val = delete $params{server};
        $self->{server} = (blessed($val) && $val->isa('Kubernetes::REST::Server'))
            ? $val
            : Kubernetes::REST::Server->new($val);
    }
    if (exists $params{credentials}) {
        my $val = delete $params{credentials};
        if (blessed($val) && $val->can('token')) {
            $self->{credentials} = $val;
        } elsif (ref($val) eq 'HASH') {
            $self->{credentials} = Kubernetes::REST::AuthToken->new($val);
        } else {
            $self->{credentials} = $val;
        }
    }
    if (exists $params{resource_map}) {
        $self->{resource_map} = delete $params{resource_map};
    }
    if (exists $params{resource_map_from_cluster}) {
        $self->{resource_map_from_cluster} = delete $params{resource_map_from_cluster};
    }
    if (exists $params{with}) {
        $self->{with} = delete $params{with};
    }

    # Resolve server/credentials via Kubeconfig (handles kubeconfig files
    # and in-cluster service account auto-detection)
    if (!$self->{server}) {
        require Kubernetes::REST::Kubeconfig;
        my $kc = Kubernetes::REST::Kubeconfig->new(
            ($self->{kubeconfig} ? (kubeconfig_path => $self->{kubeconfig}) : ()),
            ($self->{context}    ? (context_name    => $self->{context})    : ()),
        );
        if ($self->{kubeconfig} || $self->{context}) {
            # Explicit kubeconfig or context — must resolve or croak with the
            # reason; swallowed, it would only resurface as "server or
            # kubeconfig required" on first use.
            my $api = $kc->api;
            $self->{server}      = $api->server;
            $self->{credentials} = $api->credentials;
        } elsif (my $api = eval { $kc->api }) {
            # Auto-detect: kubeconfig default path or in-cluster
            $self->{server}      = $api->server;
            $self->{credentials} = $api->credentials;
        }
    }

    $self->SUPER::configure(%params);
}


# Accessors
sub kubeconfig               { $_[0]->{kubeconfig} }


sub context                  { $_[0]->{context} }


sub resource_map             { $_[0]->{resource_map} }


sub resource_map_from_cluster { $_[0]->{resource_map_from_cluster} // 0 }


sub with                     { $_[0]->{with} // [] }


sub server {
    my ($self) = @_;
    $self->{server} // croak "server or kubeconfig required";
}


sub credentials {
    my ($self) = @_;
    $self->{credentials} // croak "credentials or kubeconfig required";
}


sub rest {
    my ($self) = @_;
    $self->{_rest} //= Kubernetes::REST->new(
        server      => $self->server,
        credentials => $self->credentials,
        resource_map_from_cluster => $self->resource_map_from_cluster,
        ($self->resource_map ? (resource_map => $self->resource_map) : ()),
        with        => $self->with,
    );
}


# Lazy internal Kubernetes::REST for request building + response processing
sub _rest { $_[0]->rest }

sub new_object {
    my ($self, @args) = @_;
    return $self->rest->new_object(@args);
}


# Lazy Net::Async::HTTP instance
sub _http {
    my ($self) = @_;
    unless ($self->{_http}) {
        require Net::Async::HTTP;
        $self->{_http} = Net::Async::HTTP->new(
            user_agent => 'Net::Async::Kubernetes Perl Client',
            max_connections_per_host => 0,
        );
    }
    return $self->{_http};
}

# SSL options derived from server config, passed to every HTTP request
sub _ssl_options {
    my ($self) = @_;
    return @{$self->{_ssl_options}} if $self->{_ssl_options};

    my $server = $self->server;
    my @opts;

    if ($server->ssl_verify_server) {
        push @opts, SSL_verify_mode => SSL_VERIFY_PEER;
    } else {
        push @opts, SSL_verify_mode => SSL_VERIFY_NONE;
    }

    push @opts, SSL_ca_file   => $server->ssl_ca_file   if $server->ssl_ca_file;
    push @opts, SSL_cert_file => $server->ssl_cert_file  if $server->ssl_cert_file;
    push @opts, SSL_key_file  => $server->ssl_key_file   if $server->ssl_key_file;
    my $ca_pem = $server->ssl_ca_pem;
    if (defined $ca_pem && length $ca_pem) {
        push @opts, SSL_ca_file => $self->_materialize_ssl_pem(ca => $ca_pem);
    }
    my $cert_pem = $server->ssl_cert_pem;
    if (defined $cert_pem && length $cert_pem) {
        push @opts, SSL_cert_file => $self->_materialize_ssl_pem(cert => $cert_pem);
    }
    my $key_pem = $server->ssl_key_pem;
    if (defined $key_pem && length $key_pem) {
        push @opts, SSL_key_file => $self->_materialize_ssl_pem(key => $key_pem);
    }

    $self->{_ssl_options} = \@opts;
    return @opts;
}

sub _materialize_ssl_pem {
    my ($self, $kind, $pem) = @_;

    my $fh = File::Temp->new(
        SUFFIX => ".$kind.pem",
        UNLINK => 1,
    );
    print {$fh} $pem;
    close $fh;

    push @{ $self->{_ssl_tempfiles} ||= [] }, $fh;
    return $fh->filename;
}

# IO::K8s::expand_class fails closed: an unknown, malformed or mismatched
# apiVersion yields undef instead of a bare-name guess. Passing that undef on to
# build_path dies with "argument is not a module name", naming neither the
# resource nor the reason, so _resolve_class reports it with this.
sub _unknown_resource_error {
    my ($self, $short_class) = @_;
    return sprintf(
        "unknown resource '%s': no IO::K8s class for this apiVersion/kind"
            . " (add it to resource_map if it is a CRD)",
        defined $short_class ? $short_class : '(undef)',
    );
}

# The message for a reference where a resource name - a plain string - is
# required, and nothing for a string. A reference reaches a name position two
# ways: as the class-name argument (a manifest hashref handed to patch(),
# caught by _resolve_class below), or as the object-name argument of get() and
# delete() (a manifest hashref or an IO::K8s object, karr k70). Left unchecked
# either one stringifies into the request path (.../pods/HASH(0x...)) and only
# the server's 404 shows the error. One wording for both positions, so a
# reference is refused the same way wherever it lands.
sub _resource_name_error {
    my ($self, $name) = @_;
    return unless ref $name;
    return 'resource name must be a string, got '
        . (blessed($name) ? 'an object of class ' . ref($name)
                          : 'a ' . ref($name) . ' reference');
}

# Resolve a resource name to its IO::K8s class. Returns the class, or
# (undef, $message) when no usable class comes out of the name, which every
# caller reports per its contract - a failed Future or a croak. Kubernetes::REST's
# expand_class fails closed for a qualified name (undef) but open for a bare
# Kind: it fabricates 'IO::K8s::<Kind>' whether or not that class exists. Both
# are an unknown resource; whatever else can go wrong with the class it did
# resolve to is _usable_class's to report. A reference is no name at all -
# say a manifest hashref handed to patch() - and is refused as such
# (_resource_name_error): expand_class would stringify it into a class name
# ('IO::K8s::HASH(0x...)') and the load error would name that instead.
sub _resolve_class {
    my ($self, $name, @args) = @_;
    if (my $error = $self->_resource_name_error($name)) {
        return (undef, $error);
    }
    my $class = $self->_rest->expand_class($name, @args)
        // return (undef, $self->_unknown_resource_error($name));
    return $self->_usable_class($name, $class);
}

# What build_path would otherwise die on, synchronously and without naming the
# resource: the class must load, and it must answer api_version as a class
# method - build_path's own precondition for a path. That precondition, not a
# role, is what tells a resource class from IO::K8s's helpers (List, Resource,
# Types, Unstructured) that a bare name can land on: List has an api_version,
# but as an instance accessor that dies when called on the class. Returns the
# class, or (undef, $message) with the real cause - the load error, or "not a
# resource class". A fabricated bare-Kind name that does not load is an
# unknown resource, not a load error. IO::K8s::Unstructured is the one
# resource without a class-level api_version - its Kind is instance data -
# so, reached any other way than its own bare name 'Unstructured' (above all
# through Kubernetes::REST's discovery fallback for a Kind), it is passed on
# to build_path, which gets the Kind from _unstructured_hint.
sub _usable_class {
    my ($self, $name, $class) = @_;
    my $rest = $self->_rest;
    my $fabricated = defined $name && !ref $name && $class eq 'IO::K8s::' . $name;

    unless ($class->can('new') || eval { $rest->k8s->load_class($class); 1 }) {
        my $load_error = $@;
        return (undef, $self->_unknown_resource_error($name)) if $fabricated;
        chomp $load_error;
        return (undef, sprintf(
            "resource '%s' resolves to class %s, which cannot be loaded: %s",
            $name, $class, $load_error,
        ));
    }

    if ($class eq 'IO::K8s::Unstructured' && !$fabricated) {
        # A qualified name counts only in its own group/version (see
        # _request_path). Asking for its path confirms it exactly, from the
        # cached catalog, without a request.
        return $class unless defined $name && !ref $name && $name =~ m{/};
        my ($path) = $self->_request_path($class, $name);
        return defined $path ? $class : (undef, $self->_unknown_resource_error($name));
    }
    return $class if $class->can('api_version') && defined eval { $class->api_version };
    return (undef, sprintf(
        "resource '%s' resolves to %s, which is not a Kubernetes resource class"
            . " (it has no api_version to build a request path from)",
        $name, $class,
    ));
}

# The class of an object handed to one of the object forms (create, update,
# update_status, patch, patch_status, delete, ensure), which build their path
# from it. It is checked like a resolved name (_usable_class): an IO::K8s::List,
# a nested type such as a PodSpec, or no IO::K8s object at all has no request
# path, and build_path - or the metadata lookup before it - would die on it
# synchronously. Returns the class, or (undef, $message) naming $label, which
# each caller reports per its contract - a failed Future or a croak.
sub _object_class {
    my ($self, $label, $object) = @_;
    return (undef, "$label requires an IO::K8s object") unless blessed($object);
    my ($class, $error) = $self->_usable_class(ref($object), ref($object));
    return defined $class ? $class : (undef, "$label: $error");
}

# The extra build_path arguments for a class that resolved to
# IO::K8s::Unstructured - empty for every other class, whose path comes from
# the class alone. Unstructured has no class-level api_version: its Kind and
# apiVersion are instance data, so build_path takes them from the caller and
# looks plural and scope up in Kubernetes::REST's discovery catalog. $ident is
# what the class came from. An object gives its own kind and apiVersion. A
# name is split the way Kubernetes::REST's expand_class splits it: a qualified
# 'example.org/v1/Widget' keeps its group and version, instead of landing in
# whichever group serving a Widget discovery lists first, and an explicit
# class name ('+...', 'IO::K8s::...', any '...::...') carries no Kind. Mirrors
# the private helper of the same name in Kubernetes::REST, which is not part
# of its public seam.
sub _unstructured_hint {
    my ($self, $class, $ident) = @_;
    return () unless defined $class && $class eq 'IO::K8s::Unstructured';
    my ($kind, $api_version);
    if (blessed($ident)) {
        ($kind, $api_version) = ($ident->kind, $ident->apiVersion);
    } elsif (defined $ident && !ref $ident && $ident !~ m{\A(?:\+|IO::K8s::)}) {
        if ($ident =~ m{/}) {
            ($api_version, $kind) = $ident =~ m{\A(.*)/([^/]+)\z};
        } elsif ($ident !~ /::/) {
            $kind = $ident;
        }
    }
    return (
        (defined $kind        ? (kind        => $kind)        : ()),
        (defined $api_version ? (api_version => $api_version) : ()),
    );
}

# The request path for $class: Kubernetes::REST's build_path with %args and
# the Unstructured hint for $ident, the name or object the class came from.
# Returns the path, or (undef, $message) when build_path gives up - on
# IO::K8s::Unstructured without discovery, or without a Kind (the explicit
# class name, an object without kind) - which every caller reports per its
# contract, a failed Future or a croak, as it does a resolution error.
# build_path croaks for that, and synchronously: from a Future-returning
# method it escaped as a die. The message drops the location the croak ends
# in, which points here; a croaking caller adds its caller's own.
#
# An apiVersion in the hint - from a qualified name or the object - names
# the one group/version the request may go to; a path outside it is refused
# with Kubernetes::REST's own message (its k43), so list, delete and
# ensure_only's prune never reach another group serving a Kind of that name.
sub _request_path {
    my ($self, $class, $ident, %args) = @_;
    my %hint = $self->_unstructured_hint($class, $ident);
    my $path = eval { $self->_rest->build_path($class, %args, %hint) };
    unless (defined $path) {
        my $error = $@ ? "$@" : "cannot build a request path for $class";
        $error =~ s/\s+\z//;
        $error =~ s/ at \S+ line \d+\.\z//;
        return (undef, $error);
    }
    my $api_version = $hint{api_version};
    if (defined $api_version && length $api_version) {
        my $prefix = $api_version =~ m{/} ? "/apis/$api_version/" : "/api/$api_version/";
        return (undef, "no discovery entry for Kind '" . ($hint{kind} // '') . "'"
            . " in apiVersion '$api_version' - cannot build a path for IO::K8s::Unstructured")
            unless index($path, $prefix) == 0;
    }
    return $path;
}

# The name to hand Kubernetes::REST's inflate_object, inflate_list and
# process_watch_chunk for $class. A single-segment class of the caller's own
# ('+Gizmo' in the resource_map, which expand_class returns as 'Gizmo') must
# not read to them as the Kind Gizmo - IO::K8s::Gizmo, or whatever class the
# map gives that Kind. A loaded IO::K8s resource class therefore goes over as
# '+Class', which is taken exactly; anything else is left as it is. Mirrors
# the private helper of the same name in Kubernetes::REST, which is not part
# of its public seam.
sub _exact_class {
    my ($self, $class) = @_;
    return '+' . $class
        if defined $class && !ref $class && length $class && $class !~ /\A\+/
            && $class->can('does') && $class->does('IO::K8s::Role::Resource');
    return $class;
}

sub expand_class {
    my ($self, @args) = @_;
    my ($class, $error) = $self->_resolve_class(@args);
    croak $error unless defined $class;
    return $class;
}


sub discover {
    my ($self) = @_;

    my $rest = $self->_rest;
    return Future->done unless $self->resource_map_from_cluster;

    my %requests = $rest->prepare_discovery_requests;
    my @roots = sort keys %requests;
    return Future->needs_all(
        map { $self->_checked_request($requests{$_}, "discovery GET $_") } @roots
    )->then(sub {
        my %responses;
        @responses{@roots} = @_;
        # False for legacy discovery: nothing is kept, and Kubernetes::REST
        # reads it through its own io on first use, as without discover.
        $rest->absorb_discovery(%responses);
        return Future->done;
    });
}


sub _add_to_loop {
    my ($self, $loop) = @_;
    $self->add_child($self->_http);
}

# ============================================================================
# ASYNC CRUD METHODS - return Futures
# ============================================================================

sub list {
    my ($self, $short_class, @args) = @_;

    my $rest = $self->_rest;
    return $self->_list_request($short_class, @args)->then(sub {
        my ($class, $response) = @_;
        return $self->_checked_response($response, "list $short_class")->then(sub {
            return Future->done($rest->inflate_list($self->_exact_class($class), $response));
        });
    });
}


# list() up to the response, unchecked: resolves with the class and the raw
# Kubernetes::REST::HTTPResponse, or fails before any request when the name
# resolves to no usable class. ensure_only() needs the status itself - a 404
# there means the Kind is not served, not a failure - and must not read it
# back out of the text check_response croaks with.
sub _list_request {
    my ($self, $short_class, @args) = @_;

    return Future->fail("Invalid arguments to list()") if @args % 2;
    my %args = @args;
    my $unknown = $self->_unknown_argument_error('list', \%args,
        qw( namespace labelSelector fieldSelector ));
    return Future->fail($unknown) if defined $unknown;

    my $rest = $self->_rest;
    my ($class, $error) = $self->_resolve_class($short_class);
    return Future->fail($error) unless defined $class;

    # Selectors are query parameters; build_path only knows path segments and
    # would drop them silently, turning a filtered list into a full one.
    my %params;
    for my $selector (qw(labelSelector fieldSelector)) {
        my $value = delete $args{$selector};
        $params{$selector} = $value if defined $value;
    }

    (my $path, $error) = $self->_request_path($class, $short_class, %args);
    return Future->fail($error) unless defined $path;
    return $self->_request_unchecked('GET', $path,
        %params ? (parameters => \%params) : (),
    )->then(sub { Future->done($class, @_) });
}

sub get {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;
    my %args;
    if (@rest_args == 1) {
        $args{name} = $rest_args[0];
    } elsif (@rest_args >= 2 && $rest_args[0] !~ /^(name|namespace)$/) {
        $args{name} = shift @rest_args;
        return Future->fail("Invalid arguments to get()") if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to get()");
    }
    my $unknown = $self->_unknown_argument_error('get', \%args, qw( name namespace ));
    return Future->fail($unknown) if defined $unknown;

    # A reference in the name position (a manifest hashref, an IO::K8s object)
    # would otherwise be stringified straight into the path (k70).
    if (my $name_error = $self->_resource_name_error($args{name})) {
        return Future->fail($name_error);
    }

    my ($class, $error) = $self->_resolve_class($short_class);
    return Future->fail($error) unless defined $class;
    return Future->fail("name required for get") unless $args{name};

    (my $path, $error) = $self->_request_path($class, $short_class, %args);
    return Future->fail($error) unless defined $path;
    my $req = $rest->prepare_request('GET', $path);

    return $self->_checked_request($req, "get $short_class")->then(sub {
        my ($response) = @_;
        return Future->done($rest->inflate_object($self->_exact_class($class), $response));
    });
}


sub create {
    my ($self, $object) = @_;

    my $rest = $self->_rest;
    my ($class, $error) = $self->_object_class('create', $object);
    return Future->fail($error) unless defined $class;
    my $namespace = $object->can('metadata') && $object->metadata
        ? $object->metadata->namespace
        : undef;

    (my $path, $error) = $self->_request_path($class, $object, namespace => $namespace);
    return Future->fail($error) unless defined $path;
    my $req = $rest->prepare_request('POST', $path, body => $object->TO_JSON);

    return $self->_checked_request($req, "create " . ref($object))->then(sub {
        my ($response) = @_;
        return Future->done($rest->inflate_object($self->_exact_class($class), $response));
    });
}


sub update {
    my ($self, $object) = @_;

    my $rest = $self->_rest;
    my ($class, $error) = $self->_object_class('update', $object);
    croak $error unless defined $class;
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    (my $path, $error) = $self->_request_path($class, $object,
        name => $name, namespace => $namespace);
    croak $error unless defined $path;
    my $req = $rest->prepare_request('PUT', $path, body => $object->TO_JSON);

    return $self->_checked_request($req, "update " . ref($object))->then(sub {
        my ($response) = @_;
        return Future->done($rest->inflate_object($self->_exact_class($class), $response));
    });
}


sub update_status {
    my ($self, $object) = @_;

    my $rest = $self->_rest;
    my ($class, $error) = $self->_object_class('update_status', $object);
    croak $error unless defined $class;
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    (my $path, $error) = $self->_request_path($class, $object,
        name        => $name,
        namespace   => $namespace,
        subresource => 'status',
    );
    croak $error unless defined $path;
    my $req = $rest->prepare_request('PUT', $path, body => $object->TO_JSON);

    return $self->_checked_request($req, "update_status $class")->then(sub {
        my ($response) = @_;
        return Future->done($rest->inflate_object($self->_exact_class($class), $response));
    });
}


# Argument handling shared by patch() and patch_status(): the object form and
# both class+name forms, the required patch document and the patch type.
# Returns (undef, $class, $name, $namespace, $patch, $content_type), or just
# the failure message, which the caller turns into a failed Future. $label
# names the calling method in those messages; $default_type is the patch type
# used when the caller passes none.
sub _patch_args {
    my ($self, $label, $default_type, $class_or_object, @rest_args) = @_;

    my $rest = $self->_rest;
    my ($class, $name, $namespace, $patch, $patch_type);

    if (ref($class_or_object) && blessed($class_or_object)) {
        my $object = $class_or_object;
        ($class, my $error) = $self->_object_class($label, $object);
        return $error unless defined $class;
        my $metadata = $object->metadata or return "object must have metadata";
        $name = $metadata->name or return "object must have metadata.name";
        $namespace = $metadata->namespace;
        return "Invalid arguments to $label()" if @rest_args % 2;
        my %args = @rest_args;
        my $unknown = $self->_unknown_argument_error($label, \%args, qw( patch type ));
        return $unknown if defined $unknown;
        $patch = $args{patch} // return "$label requires 'patch' parameter";
        $patch_type = $args{type} // $default_type;
    } else {
        my ($arg_error, %args) = $self->_named_args($label, \@rest_args,
            qw( name namespace patch type ));
        return $arg_error if defined $arg_error;

        ($class, my $error) = $self->_resolve_class($class_or_object);
        return $error unless defined $class;
        $name = $args{name} or return "name required for $label";
        $namespace = $args{namespace};
        $patch = $args{patch} // return "$label requires 'patch' parameter";
        $patch_type = $args{type} // $default_type;
    }

    my %patch_types = (
        strategic => 'application/strategic-merge-patch+json',
        merge     => 'application/merge-patch+json',
        json      => 'application/json-patch+json',
    );
    my $content_type = $patch_types{$patch_type}
        // return "Unknown patch type '$patch_type'";

    return (undef, $class, $name, $namespace, $patch, $content_type);
}

sub patch {
    my ($self, $class_or_object, @rest_args) = @_;

    my $rest = $self->_rest;
    my ($error, $class, $name, $namespace, $patch, $content_type)
        = $self->_patch_args('patch', 'strategic', $class_or_object, @rest_args);
    return Future->fail($error) if defined $error;

    (my $path, $error) = $self->_request_path($class, $class_or_object,
        name => $name, namespace => $namespace);
    return Future->fail($error) unless defined $path;
    my $req = $rest->prepare_request('PATCH', $path,
        body => $patch, content_type => $content_type);

    return $self->_checked_request($req, "patch $class")->then(sub {
        my ($response) = @_;
        return Future->done($rest->inflate_object($self->_exact_class($class), $response));
    });
}


sub patch_status {
    my ($self, $class_or_object, @rest_args) = @_;

    my $rest = $self->_rest;
    my ($error, $class, $name, $namespace, $patch, $content_type)
        = $self->_patch_args('patch_status', 'merge', $class_or_object, @rest_args);
    return Future->fail($error) if defined $error;

    (my $path, $error) = $self->_request_path($class, $class_or_object,
        name        => $name,
        namespace   => $namespace,
        subresource => 'status',
    );
    return Future->fail($error) unless defined $path;
    my $req = $rest->prepare_request('PATCH', $path,
        body => $patch, content_type => $content_type);

    return $self->_checked_request($req, "patch_status $class")->then(sub {
        my ($response) = @_;
        return Future->done($rest->inflate_object($self->_exact_class($class), $response));
    });
}


sub delete {
    my ($self, @args) = @_;

    my $rest = $self->_rest;
    return $self->_delete_request(@args)->then(sub {
        my ($class, $response) = @_;
        return $self->_checked_response($response, "delete $class")->then(sub {
            return Future->done(1);
        });
    });
}


# The message for the first key of %$args (in sort order) that is not in
# @allowed, or nothing when there is none - Kubernetes::REST's wording, naming
# $label and what is allowed. Each caller reports it per its contract, a
# failed Future or a croak, before any request: an option a method does not
# take would otherwise be dropped silently (a misspelt labelSelector lists
# everything, namespace for namespaces makes ensure_only prune at cluster
# scope only).
sub _unknown_argument_error {
    my ($self, $label, $args, @allowed) = @_;
    my %allowed = map { $_ => 1 } @allowed;
    my ($unknown) = sort grep { !$allowed{$_} } keys %$args;
    return unless defined $unknown;
    return "Unknown argument '$unknown' to $label() (allowed: " . join(', ', @allowed) . ')';
}

# Argument handling shared by log(), port_forward(), exec(), attach(),
# cp_to_pod(), cp_from_pod() and the class form of patch() and patch_status()
# (in _patch_args): the name positional - METHOD('Pod', 'web',
# %options) - or keyed - METHOD('Pod', name => 'web', %options). A first
# argument that is one of @allowed starts the keyed form, so the keys read as
# the start of the keyed form and the keys _unknown_argument_error accepts are
# one list. Returns (undef, %args), or just the failure message, which the
# caller turns into a failed Future; $label names the calling method.
sub _named_args {
    my ($self, $label, $rest_args, @allowed) = @_;
    my @rest_args = @$rest_args;
    my $keys = join '|', map { quotemeta } @allowed;
    my %args;
    if (@rest_args >= 1
        && !ref($rest_args[0])
        && $rest_args[0] !~ /^(?:$keys)$/
    ) {
        $args{name} = shift @rest_args;
        return "Invalid arguments to $label()" if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return "Invalid arguments to $label()";
    }
    my $unknown = $self->_unknown_argument_error($label, \%args, @allowed);
    return $unknown if defined $unknown;
    return (undef, %args);
}

# The propagationPolicy values the API server accepts in a DELETE's
# DeleteOptions.
my @PROPAGATION_POLICIES = qw( Background Foreground Orphan );

# Nothing when $policy is absent or one of @PROPAGATION_POLICIES, else the
# message for it, naming $label - in Kubernetes::REST's wording.
sub _propagation_policy_error {
    my ($self, $label, $policy) = @_;
    return if !defined $policy || grep { $policy eq $_ } @PROPAGATION_POLICIES;
    return "Unknown propagationPolicy '$policy' for $label() (use: "
        . join(', ', @PROPAGATION_POLICIES) . ')';
}

# delete() up to the response, unchecked: resolves with the class and the raw
# Kubernetes::REST::HTTPResponse, or fails before any request on bad
# arguments - for the same reason as _list_request: ensure_only() treats a
# 404 (already gone) differently from a failure. An option delete() does not
# know is a bad argument too: a mistyped propagationPolicy dropped on the
# floor would leave a Job's Pods orphaned.
sub _delete_request {
    my ($self, $class_or_object, @rest_args) = @_;

    my ($class, $name, $namespace, %options, @known);

    if (ref($class_or_object)) {
        my $object = $class_or_object;
        ($class, my $error) = $self->_object_class('delete', $object);
        return Future->fail($error) unless defined $class;
        my $metadata = $object->metadata or return Future->fail("object must have metadata");
        $name = $metadata->name or return Future->fail("object must have metadata.name");
        $namespace = $metadata->namespace;
        return Future->fail("Invalid arguments to delete()") if @rest_args % 2;
        %options = @rest_args;
        @known = qw( propagationPolicy );
    } else {
        my %args;
        if (@rest_args == 1) {
            $args{name} = $rest_args[0];
        } elsif (@rest_args >= 2 && $rest_args[0] !~ /^(name|namespace|propagationPolicy)$/) {
            $args{name} = shift @rest_args;
            return Future->fail("Invalid arguments to delete()") if @rest_args % 2;
            %args = (%args, @rest_args);
        } elsif (@rest_args % 2 == 0) {
            %args = @rest_args;
        } else {
            return Future->fail("Invalid arguments to delete()");
        }

        ($class, my $error) = $self->_resolve_class($class_or_object);
        return Future->fail($error) unless defined $class;
        $name = delete $args{name} or return Future->fail("name required for delete");
        $namespace = delete $args{namespace};
        %options = %args;
        @known = qw( name namespace propagationPolicy );
    }

    my $policy = delete $options{propagationPolicy};
    my $unknown = $self->_unknown_argument_error('delete', \%options, @known);
    return Future->fail($unknown) if defined $unknown;
    my $policy_error = $self->_propagation_policy_error('delete', $policy);
    return Future->fail($policy_error) if defined $policy_error;

    # A reference in the name position of the class form (delete('Pod',
    # {name => 'web'})) would otherwise be stringified straight into the path
    # (k70); the object form's name comes from metadata and is always a string.
    if (my $name_error = $self->_resource_name_error($name)) {
        return Future->fail($name_error);
    }

    my ($path, $error) = $self->_request_path($class, $class_or_object,
        name => $name, namespace => $namespace);
    return Future->fail($error) unless defined $path;
    return $self->_request_unchecked('DELETE', $path,
        defined $policy ? (parameters => { propagationPolicy => $policy }) : (),
    )->then(sub { Future->done($class, @_) });
}

# One request through the Kubernetes::REST seam, resolving with the unchecked
# Kubernetes::REST::HTTPResponse -- for ensure() and ensure_only(), which
# branch on the status code (404 absent, 409 conflict), directly or through
# _list_request and _delete_request. check_response would fold that code into
# an error string it could only be read back out of with a regex.
sub _request_unchecked {
    my ($self, $method, $path, %opts) = @_;
    return $self->_do_request($self->_rest->prepare_request($method, $path, %opts));
}

# The Future for a response: done with it when Kubernetes::REST's
# check_response accepts it, failed the way Future's convention has it when
# it does not (status >= 400) - ->fail($error, 'http', $response). $error is
# exactly what check_response throws: the message string, or the error object
# of a Kubernetes::REST that has one; $response lets a caller branch on
# ->status (404 already gone, 409 conflict) instead of parsing the text.
# $context names the operation in the message, as for check_response.
sub _checked_response {
    my ($self, $response, $context) = @_;
    return Future->done($response)
        if eval { $self->_rest->check_response($response, $context); 1 };
    return Future->fail($@, http => $response);
}

# _do_request, then _checked_response: resolves with the response, or fails
# as above.
sub _checked_request {
    my ($self, $req, $context) = @_;
    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        return $self->_checked_response($response, $context);
    });
}

# Shared hashref handling for ensure() and ensure_only(): turns a manifest into
# a typed object. A manifest's apiVersion is authoritative - with one, the
# class is resolved as that exact group/version/Kind, and an apiVersion no
# class serves croaks instead of falling back to the version the bare Kind
# happens to map to (HorizontalPodAutoscaler alone means autoscaling/v2, a
# different endpoint and schema than an autoscaling/v1 manifest). Without an
# apiVersion the bare Kind resolves as it always did. Either way the class
# must be usable (_usable_class): one that does not load croaks with its load
# error. The class is resolved here, so it goes to struct_to_object with a
# '+', which IO::K8s takes as that exact class: struct_to_object resolves a
# plain name again, and a single-segment class of the caller's own ('+Gizmo'
# in the resource_map, which expand_class returns as 'Gizmo') reads to it as
# the Kind Gizmo - IO::K8s::Gizmo, or whatever class the map gives that Kind.
# $label only appears in croak messages.
sub _manifest_to_object {
    my ($self, $label, $manifest) = @_;
    my $kind = $manifest->{kind} or croak "$label: hashref must have 'kind'";
    my $api_version = $manifest->{apiVersion};
    my $rest = $self->_rest;

    return $rest->k8s->struct_to_object('+' . $self->expand_class($kind), $manifest)
        unless defined $api_version && length $api_version;

    my $resolved = $rest->expand_class($kind, $api_version)
        // croak "$label: no IO::K8s class for apiVersion '$api_version', kind '$kind'"
            . " (add it to resource_map if it is a CRD)";
    my ($class, $error) = $self->_usable_class("$api_version/$kind", $resolved);
    croak "$label: $error" unless defined $class;
    return $rest->k8s->struct_to_object('+' . $class, $manifest);
}

# The apiVersion and Kind an object is an instance of, for ensure() and
# ensure_only() to tell resources apart by. A typed object answers from its
# class (api_version(), kind()); IO::K8s::Unstructured from its instance data,
# since its class name says nothing about what it holds. The last segment of a
# class name is not enough on its own: a CRD is free to reuse a built-in Kind
# name in its own group. Mirrors the private helper of the same name in
# Kubernetes::REST, which is not part of its public seam.
sub _api_version_and_kind {
    my ($self, $object) = @_;
    my $api_version = ref($object) eq 'IO::K8s::Unstructured' ? $object->apiVersion
                    : $object->can('api_version')           ? $object->api_version
                    : undef;
    my $kind = $object->can('kind') ? $object->kind : undef;
    ($kind = ref $object) =~ s/.*::// unless defined $kind;
    return ($api_version // '', $kind);
}

sub ensure {
    my ($self, $object) = @_;

    my $rest = $self->_rest;
    $object = $self->_manifest_to_object('ensure', $object) if ref($object) eq 'HASH';
    croak "ensure requires an IO::K8s object or hashref" unless blessed($object);

    my ($class, $error) = $self->_object_class('ensure', $object);
    croak $error unless defined $class;
    my ($api_version, $kind) = $self->_api_version_and_kind($object);
    # The special cases below are the built-in core v1 PersistentVolumeClaim
    # and batch/v1 Job only. The apiVersion is compared exactly, not just its
    # group: the Job branch reads batch/v1's status fields and deletes what it
    # takes for a failed Job, so an apiVersion it was not written for falls
    # through to the plain update, where a mismatch fails loudly instead.
    my $is_pvc = $api_version eq 'v1'       && $kind eq 'PersistentVolumeClaim';
    my $is_job = $api_version eq 'batch/v1' && $kind eq 'Job';
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;
    (my $path, $error) = $self->_request_path($class, $object,
        name => $name, namespace => $namespace);
    croak $error unless defined $path;
    (my $collection, $error) = $self->_request_path($class, $object, namespace => $namespace);
    croak $error unless defined $collection;

    # GET the object as the server has it now; $context names the step.
    my $fetch = sub {
        my ($context) = @_;
        return $self->_checked_request($rest->prepare_request('GET', $path), "$context $kind/$name")
            ->then(sub {
                my ($response) = @_;
                return Future->done($rest->inflate_object($self->_exact_class($class), $response));
            });
    };

    # PUT at the server's resourceVersion. A 409 means the object changed
    # between GET and PUT: fetch it once more and retry once, no further.
    my $replace = sub {
        my ($existing) = @_;
        $metadata->resourceVersion($existing->metadata->resourceVersion);
        return $self->_request_unchecked('PUT', $path, body => $object->TO_JSON)->then(sub {
            my ($response) = @_;
            if ($response->status == 409) {
                return $fetch->('ensure refetch')->then(sub {
                    my ($current) = @_;
                    $metadata->resourceVersion($current->metadata->resourceVersion);
                    return $self->update($object);
                });
            }
            return $self->_checked_response($response, "update $class")->then(sub {
                return Future->done($rest->inflate_object($self->_exact_class($class), $response));
            });
        });
    };

    # The object as the server has it, however ensure found out it exists.
    my $apply_to_existing = sub {
        my ($existing) = @_;

        # An existing claim is never rewritten.
        return Future->done($existing) if $is_pvc;

        # A Job's pod template is immutable: a running or succeeded Job stays,
        # any other is replaced - deleted with its Pods (Background), which
        # the API server's default for a Job would orphan. A failing delete
        # does not stop the create. The status is read from TO_JSON, not
        # status(): an IO::K8s::Unstructured Job has no status accessor.
        if ($is_job) {
            my $status = $existing->TO_JSON->{status} || {};
            return Future->done($existing)
                if $status->{succeeded} || $status->{active};
            return Future->call(sub { $self->delete($existing, propagationPolicy => 'Background') })
                ->else(sub { Future->done })
                ->then(sub { $self->create($object) });
        }

        return $replace->($existing);
    };

    # POST. A 409 means it was created by someone else after our GET: from
    # there on it is an existing object like any other, special cases
    # included - a Job must not get a PUT onto its immutable Pod template.
    my $create = sub {
        return $self->_request_unchecked('POST', $collection, body => $object->TO_JSON)->then(sub {
            my ($response) = @_;
            return $fetch->('ensure post-409 get')->then($apply_to_existing)
                if $response->status == 409;
            return $self->_checked_response($response, "create $class")->then(sub {
                return Future->done($rest->inflate_object($self->_exact_class($class), $response));
            });
        });
    };

    return $self->_request_unchecked('GET', $path)->then(sub {
        my ($response) = @_;
        return $create->() if $response->status == 404;
        return $self->_checked_response($response, "ensure get $kind/$name")->then(sub {
            return $apply_to_existing->($rest->inflate_object($self->_exact_class($class), $response));
        });
    });
}


sub ensure_all {
    my ($self, @objects) = @_;

    # Strictly one after another: object N+1 is only started once object N
    # is done, so a later object may rely on an earlier one (a Namespace and
    # what lives in it). Any error, a croak from ensure() included, fails
    # the chain and nothing after it is started.
    my @results;
    my $f = Future->done;
    for my $object (@objects) {
        $f = $f->then(sub {
            return $self->ensure($object);
        })->then(sub {
            push @results, @_;
            return Future->done;
        });
    }

    return $f->then(sub { Future->done(@results) });
}


sub ensure_only {
    my ($self, @args) = @_;

    # Before anything is applied: an odd list drops a value (no objects
    # prunes everything carrying the label), namespace for namespaces would
    # prune at cluster scope only.
    croak "Invalid arguments to ensure_only()" if @args % 2;
    my %args = @args;
    my $unknown = $self->_unknown_argument_error('ensure_only', \%args,
        qw( label objects kinds namespaces propagationPolicy ));
    croak $unknown if defined $unknown;

    my $rest       = $self->_rest;
    my $label      = $args{label} or croak "ensure_only requires 'label'";
    # Background unless told otherwise: the API server's own default leaves
    # the Pods of a pruned Job behind.
    my $policy     = $args{propagationPolicy} // 'Background';
    my $policy_error = $self->_propagation_policy_error('ensure_only', $policy);
    croak $policy_error if defined $policy_error;
    my @objects    = @{ $args{objects} || [] };
    my @kinds      = @{ $args{kinds} || [] };
    my @namespaces = @{ $args{namespaces} || [undef] };

    # Every hashref is resolved before the first request, so one that cannot
    # be (no kind, an apiVersion no class serves) stops the whole call.
    for my $object (@objects) {
        $object = $self->_manifest_to_object('ensure_only', $object)
            if ref($object) eq 'HASH';
    }

    # (group, Kind, namespace, name), taken from the object on both sides -
    # never from the kinds entry, which may be qualified ('autoscaling/v1/...')
    # and would then match nothing, deleting the objects just applied. Group
    # and Kind come from _api_version_and_kind: class-derived for a typed
    # object, instance data for IO::K8s::Unstructured. The group keeps the same
    # Kind name in two groups apart (Istio's and the Gateway API's Gateway);
    # the core group is ''. No version in the key: the same resource listed
    # through another version's class is still the same resource.
    my $key_of = sub {
        my ($object) = @_;
        my ($api_version, $kind) = $self->_api_version_and_kind($object);
        my ($group) = $api_version =~ m{\A(.*)/[^/]*\z};
        my $metadata = $object->metadata;
        return join("\0", $group // '', $kind, $metadata->namespace // '', $metadata->name);
    };

    # A failed list or delete leaves stale objects behind, so it is reported
    # rather than swallowed - but only a real failure: a 404 on the list means
    # the cluster does not serve the Kind, a 404 on the delete that the object
    # is already gone. The status comes from the unchecked response, never
    # from the text of an error. A caught croak already ends in its own
    # location, which carp adds again, so the reason drops it.
    my $where = sub {
        my ($namespace) = @_;
        return defined $namespace ? "in namespace '$namespace'" : 'at cluster scope';
    };
    my $reason_of = sub {
        my ($error) = @_;
        $error = defined $error ? "$error" : 'unknown error';
        $error =~ s/\s+\z//;
        $error =~ s/ at \S+ line \d+\.\z//;
        return $error;
    };
    my $prune = sub {
        my ($item) = @_;
        return Future->call(sub {
            $self->_delete_request($item, propagationPolicy => $policy);
        })->then(sub {
            my ($class, $response) = @_;
            return Future->done if $response->status == 404;
            return $self->_checked_response($response, "delete $class");
        })->else(sub {
            my ($error) = @_;
            my (undef, $kind) = $self->_api_version_and_kind($item);
            carp "ensure_only: cannot delete $kind '" . $item->metadata->name . "' "
                . $where->($item->metadata->namespace) . ': ' . $reason_of->($error);
            return Future->done;
        });
    };

    return $self->ensure_all(@objects)->then(sub {
        my @applied = @_;
        my %expected = map { $key_of->($_) => 1 } @objects;

        # One Kind x namespace after another, each delete after the one
        # before, and on past every failure.
        my $f = Future->done;
        for my $kind (@kinds) {
            for my $namespace (@namespaces) {
                $f = $f->then(sub {
                    return Future->call(sub {
                        $self->_list_request($kind,
                            labelSelector => $label,
                            (defined $namespace ? (namespace => $namespace) : ()),
                        );
                    })->then(sub {
                        my ($class, $response) = @_;
                        return Future->done if $response->status == 404;
                        return $self->_checked_response($response, "list $kind")->then(sub {
                            return Future->done($rest->inflate_list($self->_exact_class($class), $response));
                        });
                    })->else(sub {
                        my ($error) = @_;
                        carp "ensure_only: cannot list $kind " . $where->($namespace)
                            . ', nothing pruned there: ' . $reason_of->($error);
                        return Future->done;
                    })->then(sub {
                        my ($list) = @_;
                        my $deletes = Future->done;
                        return $deletes unless $list;
                        for my $item (@{ $list->items }) {
                            next if $expected{ $key_of->($item) };
                            $deletes = $deletes->then(sub { $prune->($item) });
                        }
                        return $deletes;
                    });
                });
            }
        }

        return $f->then(sub { Future->done(@applied) });
    });
}


sub log {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;

    # Support: log('Pod', 'name', ...) and log('Pod', name => 'name', ...)
    my ($arg_error, %args) = $self->_named_args('log', \@rest_args, qw( name namespace
        container follow tailLines sinceSeconds sinceTime timestamps previous limitBytes
        on_line ));
    return Future->fail($arg_error) if defined $arg_error;

    return Future->fail("name required for log") unless $args{name};

    my $on_line       = delete $args{on_line};
    my $container     = delete $args{container};
    my $follow        = delete $args{follow};
    my $tail_lines    = delete $args{tailLines};
    my $since_seconds = delete $args{sinceSeconds};
    my $since_time    = delete $args{sinceTime};
    my $timestamps    = delete $args{timestamps};
    my $previous      = delete $args{previous};
    my $limit_bytes   = delete $args{limitBytes};

    my ($class, $error) = $self->_resolve_class($short_class);
    return Future->fail($error) unless defined $class;
    (my $path, $error) = $self->_request_path($class, $short_class, %args);
    return Future->fail($error) unless defined $path;
    $path .= '/log';

    my %params;
    $params{container}    = $container     if defined $container;
    $params{follow}       = 'true'         if $follow;
    $params{tailLines}    = $tail_lines    if defined $tail_lines;
    $params{sinceSeconds} = $since_seconds if defined $since_seconds;
    $params{sinceTime}    = $since_time    if defined $since_time;
    $params{timestamps}   = 'true'         if $timestamps;
    $params{previous}     = 'true'         if $previous;
    $params{limitBytes}   = $limit_bytes   if defined $limit_bytes;

    if ($on_line) {
        my $req = $rest->prepare_request('GET', $path, parameters => \%params);
        my $buffer = '';

        return $self->_do_streaming_request($req, sub {
            my ($chunk) = @_;
            for my $event ($rest->process_log_chunk(\$buffer, $chunk)) {
                $on_line->($event);
            }
        })->then(sub {
            my ($response) = @_;
            return $self->_checked_response($response, "log $short_class");
        })->then(sub {
            if (length $buffer) {
                $on_line->(Kubernetes::REST::LogEvent->new(line => $buffer));
            }
            return Future->done(undef);
        });
    }

    my $req = $rest->prepare_request('GET', $path,
        %params ? (parameters => \%params) : (),
    );
    return $self->_checked_request($req, "log $short_class")->then(sub {
        my ($response) = @_;
        return Future->done($response->content);
    });
}


sub port_forward {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;

    # Support: port_forward('Pod', 'name', ...) and port_forward('Pod', name => 'name', ...)
    my ($arg_error, %args) = $self->_named_args('port_forward', \@rest_args,
        qw( name namespace ports subprotocol on_open on_frame on_close on_error ));
    return Future->fail($arg_error) if defined $arg_error;

    return Future->fail("name required for port_forward") unless $args{name};

    my $ports = delete $args{ports};
    return Future->fail("ports required for port_forward") unless defined $ports;
    $ports = [$ports] unless ref($ports) eq 'ARRAY';
    return Future->fail("ports required for port_forward") unless @$ports;
    for my $p (@$ports) {
        return Future->fail("invalid port '$p' for port_forward")
            unless defined($p) && $p =~ /^\d+$/ && $p > 0 && $p <= 65535;
    }

    my $subprotocol = delete $args{subprotocol} // 'v4.channel.k8s.io';
    my $on_open  = delete $args{on_open};
    my $on_frame = delete $args{on_frame};
    my $on_close = delete $args{on_close};
    my $on_error = delete $args{on_error};

    my ($class, $error) = $self->_resolve_class($short_class);
    return Future->fail($error) unless defined $class;
    (my $path, $error) = $self->_request_path($class, $short_class, %args);
    return Future->fail($error) unless defined $path;
    $path .= '/portforward';

    # Keep compatibility with Kubernetes::REST >= 1.100 by expanding repeated
    # ports query params here instead of relying on arrayref parameter support.
    my $query = join('&', map { "ports=$_" } @$ports);
    my $path_with_query = $query ? "$path?$query" : $path;

    my $req = $rest->prepare_request('GET', $path_with_query,
        headers    => {
            Accept                   => '*/*',
            Connection               => 'Upgrade',
            Upgrade                  => 'websocket',
            'Sec-WebSocket-Protocol' => $subprotocol,
        },
    );

    return $self->_do_duplex_request($req,
        caller   => 'port_forward',
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}


sub exec {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;

    # Support: exec('Pod', 'name', ...) and exec('Pod', name => 'name', ...)
    my ($arg_error, %args) = $self->_named_args('exec', \@rest_args, qw( name namespace command
        container stdin stdout stderr tty subprotocol on_open on_frame on_close on_error ));
    return Future->fail($arg_error) if defined $arg_error;

    return Future->fail("name required for exec") unless $args{name};

    my $command = delete $args{command};
    return Future->fail("command required for exec") unless defined $command;
    $command = [$command] unless ref($command) eq 'ARRAY';
    return Future->fail("command required for exec") unless @$command;
    for my $part (@$command) {
        return Future->fail("invalid command element for exec")
            unless defined($part) && !ref($part) && length $part;
    }

    my $container = delete $args{container};
    my $stdin  = delete($args{stdin})  ? 1 : 0;
    my $stdout = exists($args{stdout}) ? (delete($args{stdout}) ? 1 : 0) : 1;
    my $stderr = exists($args{stderr}) ? (delete($args{stderr}) ? 1 : 0) : 1;
    my $tty    = delete($args{tty})    ? 1 : 0;

    my $subprotocol = delete $args{subprotocol} // 'v4.channel.k8s.io';
    my $on_open  = delete $args{on_open};
    my $on_frame = delete $args{on_frame};
    my $on_close = delete $args{on_close};
    my $on_error = delete $args{on_error};

    my ($class, $error) = $self->_resolve_class($short_class);
    return Future->fail($error) unless defined $class;
    (my $path, $error) = $self->_request_path($class, $short_class, %args);
    return Future->fail($error) unless defined $path;
    $path .= '/exec';

    my %params = (
        command => $command,
        stdin   => $stdin  ? 'true' : 'false',
        stdout  => $stdout ? 'true' : 'false',
        stderr  => $stderr ? 'true' : 'false',
        tty     => $tty    ? 'true' : 'false',
    );
    $params{container} = $container if defined $container;

    my $req = $rest->prepare_request('GET', $path,
        parameters => \%params,
        headers    => {
            Accept                   => '*/*',
            Connection               => 'Upgrade',
            Upgrade                  => 'websocket',
            'Sec-WebSocket-Protocol' => $subprotocol,
        },
    );

    return $self->_do_duplex_request($req,
        caller   => 'exec',
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}


sub attach {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;

    # Support: attach('Pod', 'name', ...) and attach('Pod', name => 'name', ...)
    my ($arg_error, %args) = $self->_named_args('attach', \@rest_args, qw( name namespace
        container stdin stdout stderr tty subprotocol on_open on_frame on_close on_error ));
    return Future->fail($arg_error) if defined $arg_error;

    return Future->fail("name required for attach") unless $args{name};

    my $container = delete $args{container};
    my $stdin  = delete($args{stdin})  ? 1 : 0;
    my $stdout = exists($args{stdout}) ? (delete($args{stdout}) ? 1 : 0) : 1;
    my $stderr = exists($args{stderr}) ? (delete($args{stderr}) ? 1 : 0) : 1;
    my $tty    = delete($args{tty})    ? 1 : 0;

    my $subprotocol = delete $args{subprotocol} // 'v4.channel.k8s.io';
    my $on_open  = delete $args{on_open};
    my $on_frame = delete $args{on_frame};
    my $on_close = delete $args{on_close};
    my $on_error = delete $args{on_error};

    my ($class, $error) = $self->_resolve_class($short_class);
    return Future->fail($error) unless defined $class;
    (my $path, $error) = $self->_request_path($class, $short_class, %args);
    return Future->fail($error) unless defined $path;
    $path .= '/attach';

    my %params = (
        stdin   => $stdin  ? 'true' : 'false',
        stdout  => $stdout ? 'true' : 'false',
        stderr  => $stderr ? 'true' : 'false',
        tty     => $tty    ? 'true' : 'false',
    );
    $params{container} = $container if defined $container;

    my $req = $rest->prepare_request('GET', $path,
        parameters => \%params,
        headers    => {
            Accept                   => '*/*',
            Connection               => 'Upgrade',
            Upgrade                  => 'websocket',
            'Sec-WebSocket-Protocol' => $subprotocol,
        },
    );

    return $self->_do_duplex_request($req,
        caller   => 'attach',
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}


sub cp_to_pod {
    my ($self, $short_class, @rest_args) = @_;

    my $loop = eval { $self->loop };
    return Future->fail("cp_to_pod requires Net::Async::Kubernetes to be added to an IO::Async::Loop")
        unless $loop;

    my ($arg_error, %args) = $self->_named_args('cp_to_pod', \@rest_args,
        qw( name namespace container local remote chunk_size ));
    return Future->fail($arg_error) if defined $arg_error;

    return Future->fail("name required for cp_to_pod") unless $args{name};

    my $local = delete $args{local};
    my $remote = delete $args{remote};
    return Future->fail("local path required for cp_to_pod") unless defined $local && length $local;
    return Future->fail("remote path required for cp_to_pod") unless defined $remote && length $remote;
    return Future->fail("local file '$local' does not exist for cp_to_pod") unless -e $local;
    return Future->fail("local path '$local' is not a file for cp_to_pod") unless -f $local;

    my $chunk_size = delete($args{chunk_size}) // 64 * 1024;
    return Future->fail("invalid chunk_size '$chunk_size' for cp_to_pod")
        unless defined($chunk_size) && $chunk_size =~ /^\d+$/ && $chunk_size > 0;

    open my $fh, '<:raw', $local
        or return Future->fail("cannot read local file '$local' for cp_to_pod: $!");
    local $/ = undef;
    my $bytes = <$fh>;
    close $fh;
    $bytes = '' unless defined $bytes;

    my $size = length($bytes);
    my $stderr = '';
    my $status_payload = '';
    my $done = $loop->new_future;

    return $self->exec($short_class, $args{name},
        namespace => $args{namespace},
        (defined($args{container}) ? (container => $args{container}) : ()),
        command   => ['sh', '-c', 'head -c "$1" > "$2"', 'k8s-cp', $size, $remote],
        stdin     => 1,
        stdout    => 0,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub {
            my ($channel, $payload) = @_;
            $stderr .= $payload if $channel == 2;
            $status_payload .= $payload if $channel == 3;
        },
        on_close  => sub {
            return if $done->is_ready;
            if ($status_payload =~ /"status"\s*:\s*"Failure"/i) {
                $done->fail("cp_to_pod failed: $status_payload");
            } else {
                $done->done({
                    local   => $local,
                    remote  => $remote,
                    bytes   => $size,
                    stderr  => $stderr,
                    status  => $status_payload,
                });
            }
        },
        on_error  => sub {
            my ($err) = @_;
            $done->fail("cp_to_pod transport error: $err") unless $done->is_ready;
        },
    )->then(sub {
        my ($session) = @_;
        return $self->_send_stdin_chunks($session, $bytes, $chunk_size)
            ->then(sub { return $done; });
    });
}


sub cp_from_pod {
    my ($self, $short_class, @rest_args) = @_;

    my $loop = eval { $self->loop };
    return Future->fail("cp_from_pod requires Net::Async::Kubernetes to be added to an IO::Async::Loop")
        unless $loop;

    my ($arg_error, %args) = $self->_named_args('cp_from_pod', \@rest_args,
        qw( name namespace container local remote ));
    return Future->fail($arg_error) if defined $arg_error;

    return Future->fail("name required for cp_from_pod") unless $args{name};

    my $local = delete $args{local};
    my $remote = delete $args{remote};
    return Future->fail("local path required for cp_from_pod") unless defined $local && length $local;
    return Future->fail("remote path required for cp_from_pod") unless defined $remote && length $remote;
    return Future->fail("local path '$local' is a directory for cp_from_pod") if -d $local;

    my $stdout = '';
    my $stderr = '';
    my $status_payload = '';
    my $done = $loop->new_future;

    return $self->exec($short_class, $args{name},
        namespace => $args{namespace},
        (defined($args{container}) ? (container => $args{container}) : ()),
        command   => ['cat', $remote],
        stdin     => 0,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub {
            my ($channel, $payload) = @_;
            $stdout .= $payload if $channel == 1;
            $stderr .= $payload if $channel == 2;
            $status_payload .= $payload if $channel == 3;
        },
        on_close  => sub {
            return if $done->is_ready;
            if ($status_payload =~ /"status"\s*:\s*"Failure"/i) {
                $done->fail("cp_from_pod failed: $status_payload");
                return;
            }

            open my $fh, '>:raw', $local
                or do {
                    $done->fail("cannot write local file '$local' for cp_from_pod: $!");
                    return;
                };
            print {$fh} $stdout;
            close $fh;

            $done->done({
                local   => $local,
                remote  => $remote,
                bytes   => length($stdout),
                stderr  => $stderr,
                status  => $status_payload,
            });
        },
        on_error  => sub {
            my ($err) = @_;
            $done->fail("cp_from_pod transport error: $err") unless $done->is_ready;
        },
    )->then(sub { return $done; });
}


sub _send_stdin_chunks {
    my ($self, $session, $bytes, $chunk_size) = @_;

    my $f = Future->done;
    my $len = length($bytes // '');
    for (my $off = 0; $off < $len; $off += $chunk_size) {
        my $chunk = substr($bytes, $off, $chunk_size);
        $f = $f->then(sub {
            return $session->write_stdin($chunk);
        });
    }

    return $f;
}

# ============================================================================
# WATCHER FACTORY
# ============================================================================

sub watcher {
    my ($self, $resource, @args) = @_;

    croak "Invalid arguments to watcher()" if @args % 2;
    my $watcher = Net::Async::Kubernetes::Watcher->new(
        kube     => $self,
        resource => $resource,
        @args,
    );

    $self->add_child($watcher);
    return $watcher;
}


sub controller {
    my ($self, @args) = @_;

    croak "Invalid arguments to controller()" if @args % 2;
    my $controller = Net::Async::Kubernetes::Controller->new(
        kube => $self,
        @args,
    );

    $self->add_child($controller);
    return $controller;
}


# ============================================================================
# HTTP TRANSPORT
# ============================================================================

sub _do_request {
    my ($self, $req) = @_;

    my $uri = URI->new($req->url);

    my @content_args;
    if (defined $req->content) {
        my $ct = $req->headers->{'Content-Type'} // 'application/json';
        @content_args = (content => $req->content, content_type => $ct);
    }

    return $self->_http->do_request(
        method  => $req->method,
        uri     => $uri,
        headers => $req->headers,
        @content_args,
        $self->_ssl_options,
    )->then(sub {
        my ($response) = @_;
        return Future->done(Kubernetes::REST::HTTPResponse->new(
            status  => $response->code,
            content => $response->decoded_content // $response->content // '',
        ));
    });
}

# Resolves with the response status and, for an error response (>= 400), its
# body as content. An error body is the Status explaining the rejection, not
# stream data: it never reaches $on_chunk, where it would pass for a watch
# event or a log line, and is kept for the caller's check_response instead.
sub _do_streaming_request {
    my ($self, $req, $on_chunk) = @_;

    my $uri = URI->new($req->url);
    my $error_body = '';

    return $self->_http->do_request(
        method  => $req->method,
        uri     => $uri,
        headers => $req->headers,
        on_header => sub {
            my ($response) = @_;
            my $is_error = $response->code >= 400;
            return sub {
                # Called once more without arguments at the end of the body;
                # what it returns is what the request Future resolves with.
                return $response unless @_;
                my ($chunk) = @_;
                return unless defined $chunk;
                if ($is_error) {
                    $error_body .= $chunk;
                } else {
                    $on_chunk->($chunk);
                }
                return;
            };
        },
        $self->_ssl_options,
    )->then(sub {
        my ($response) = @_;
        return Future->done(Kubernetes::REST::HTTPResponse->new(
            status  => $response->code,
            content => $error_body,
        ));
    });
}

sub _do_duplex_request {
    my ($self, $req, %callbacks) = @_;
    my $caller_name = delete($callbacks{caller}) // 'duplex request';
    my $loop = eval { $self->loop };
    return Future->fail("$caller_name requires Net::Async::Kubernetes to be added to an IO::Async::Loop")
        unless $loop;

    my $on_open  = $callbacks{on_open};
    my $on_frame = $callbacks{on_frame};
    my $on_close = $callbacks{on_close};
    my $on_error = $callbacks{on_error};

    my $ws_url = $self->_build_websocket_url($req->url);
    my $ws_req = $self->_build_websocket_request($req);

    my $client;
    my $session;
    my $close_notified = 0;

    my $detach_client = sub {
        return unless $client;
        return unless $client->can('parent');
        return unless $client->parent && $client->parent == $self;
        $self->remove_child($client);
    };

    my $notify_error = sub {
        my ($err) = @_;
        return unless ref($on_error) eq 'CODE';
        my $ok = eval { $on_error->($err); 1 };
        return if $ok;
        warn $@;
    };

    my $notify_close = sub {
        return if $close_notified++;
        if (ref($on_close) eq 'CODE') {
            my $ok = eval { $on_close->(@_); 1 };
            $notify_error->($@) unless $ok;
        }
        $detach_client->();
    };

    my $dispatch_frame = sub {
        my ($bytes) = @_;
        return unless ref($on_frame) eq 'CODE';
        return unless defined $bytes;
        return unless length $bytes;

        my $channel = ord(substr($bytes, 0, 1));
        my $payload = substr($bytes, 1);
        my $ok = eval { $on_frame->($channel, $payload); 1 };
        $notify_error->($@) unless $ok;
    };

    $client = $self->_make_websocket_client(
        on_binary_frame => sub {
            my (undef, $bytes) = @_;
            $dispatch_frame->($bytes);
        },
        on_text_frame => sub {
            my (undef, $text) = @_;
            return unless defined $text;
            my $bytes = $text;
            utf8::encode($bytes) if utf8::is_utf8($bytes);
            $dispatch_frame->($bytes);
        },
        on_close_frame => sub {
            my (undef, $payload) = @_;
            $notify_close->($payload);
        },
        on_read_error => sub {
            my (undef, $errno, $msg) = @_;
            my $err = defined $msg && length $msg ? $msg : ($errno // 'websocket read error');
            $notify_error->($err);
        },
        on_write_error => sub {
            my (undef, $errno, $msg) = @_;
            my $err = defined $msg && length $msg ? $msg : ($errno // 'websocket write error');
            $notify_error->($err);
        },
        on_closed => sub {
            $notify_close->();
        },
    );

    $self->add_child($client);

    return $client->connect(
        url => $ws_url,
        req => $ws_req,
        $self->_ssl_options,
    )->then(sub {
        $session = Net::Async::Kubernetes::PortForwardSession->new(
            ws_client => $client,
        );

        if (ref($on_open) eq 'CODE') {
            my $ok = eval { $on_open->($session); 1 };
            $notify_error->($@) unless $ok;
        }

        return Future->done($session);
    })->else(sub {
        my ($error) = @_;
        $notify_error->($error);
        $detach_client->();
        return Future->fail($error);
    });
}

sub _build_websocket_url {
    my ($self, $url) = @_;
    $url =~ s/^https:/wss:/i;
    $url =~ s/^http:/ws:/i;
    return $url;
}

sub _build_websocket_request {
    my ($self, $req) = @_;
    my $headers = $req->headers || {};

    my @extra_headers;
    my $subprotocol;

    for my $name (keys %$headers) {
        my $value = $headers->{$name};
        next unless defined $value;

        my $lc = lc($name);
        if ($lc eq 'sec-websocket-protocol') {
            $subprotocol = $value;
            next;
        }
        next if $lc eq 'connection';
        next if $lc eq 'upgrade';
        next if $lc eq 'host';
        next if $lc eq 'sec-websocket-key';
        next if $lc eq 'sec-websocket-version';

        push @extra_headers, $name, $value;
    }

    return Protocol::WebSocket::Request->new(
        headers => \@extra_headers,
        (defined $subprotocol ? (subprotocol => $subprotocol) : ()),
    );
}

sub _make_websocket_client {
    my ($self, %args) = @_;
    require Net::Async::WebSocket::Client;
    return Net::Async::WebSocket::Client->new(%args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Kubernetes - Async Kubernetes client for IO::Async

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::Kubernetes;

    my $loop = IO::Async::Loop->new;

    # From kubeconfig (easiest)
    my $kube = Net::Async::Kubernetes->new(
        kubeconfig => "$ENV{HOME}/.kube/config",
    );
    $loop->add($kube);

    # In-cluster: auto-detects service account token (no config needed)
    my $kube = Net::Async::Kubernetes->new;
    $loop->add($kube);

    # Or with explicit server/credentials
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://kubernetes.local:6443' },
        credentials => { token => $token },
    );
    $loop->add($kube);

    # Future-based CRUD
    my $pods = $kube->list('Pod', namespace => 'default')->get;

    my $pod = $kube->get('Pod', 'nginx', namespace => 'default')->get;

    my $patched = $kube->patch('Pod', 'nginx',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'staging' } } },
    )->get;

    $kube->delete('Pod', 'nginx', namespace => 'default')->get;

    # Pod logs (one-shot)
    my $text = $kube->log('Pod', 'nginx',
        namespace => 'default',
        tailLines => 100,
    )->get;

    # Pod logs (streaming)
    $kube->log('Pod', 'nginx',
        namespace => 'default',
        follow    => 1,
        on_line   => sub { my ($event) = @_; say $event->line },
    )->get;

    # Port-forward (built-in websocket duplex support)
    my $pf = $kube->port_forward('Pod', 'nginx',
        namespace => 'default',
        ports     => [8080],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    )->get;

    $pf->write_channel(0, "GET / HTTP/1.1\r\n\r\n");
    $pf->close(code => 1000);

    # Pod exec (websocket duplex)
    my $exec = $kube->exec('Pod', 'nginx',
        namespace => 'default',
        command   => ['sh', '-c', 'id'],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    )->get;
    $exec->write_stdin("id\n");
    $exec->resize(width => 120, height => 40);

    # Pod attach (websocket duplex)
    my $attach = $kube->attach('Pod', 'nginx',
        namespace => 'default',
        container => 'app',
        stdin     => 1,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    )->get;
    $attach->write_stdin("help\n");

    # Copy local file to pod and back (built on exec)
    $kube->cp_to_pod('Pod', 'nginx',
        namespace => 'default',
        local     => '/tmp/local.txt',
        remote    => '/tmp/remote.txt',
    )->get;
    $kube->cp_from_pod('Pod', 'nginx',
        namespace => 'default',
        remote    => '/tmp/remote.txt',
        local     => '/tmp/downloaded.txt',
    )->get;

    # Watcher with auto-reconnect
    my $watcher = $kube->watcher('Pod',
        namespace   => 'default',
        on_added    => sub { my ($pod) = @_; say "Added: " . $pod->metadata->name },
        on_modified => sub { my ($pod) = @_; say "Modified: " . $pod->metadata->name },
        on_deleted  => sub { my ($pod) = @_; say "Deleted: " . $pod->metadata->name },
    );

    $loop->run;

=head1 DESCRIPTION

C<Net::Async::Kubernetes> is an async Kubernetes client built on L<IO::Async>.
It extends L<IO::Async::Notifier> and uses L<Net::Async::HTTP> for
non-blocking HTTP communication, plus L<Net::Async::WebSocket::Client> for
duplex subresources like pod port-forward.

All CRUD, log, port-forward, exec, attach, and cp helper methods return L<Future> objects. The
L<Net::Async::Kubernetes::Watcher>
provides auto-reconnecting event streaming with separate callbacks per
event type.

Request preparation and response processing are delegated to
L<Kubernetes::REST>, so the same IO::K8s object inflation, short class
names, and CRD support are available.

Authentication is automatically resolved in the following order:

=over 4

=item 1. Explicit C<server> and C<credentials> parameters

=item 2. C<kubeconfig> file (via L<Kubernetes::REST::Kubeconfig>)

=item 3. In-cluster service account token at
C</var/run/secrets/kubernetes.io/serviceaccount/token> (automatic when
running inside a Kubernetes pod)

=back

=head2 configure

Internal L<IO::Async::Notifier> configuration method. Handles initialization
of C<kubeconfig>, C<context>, C<server>, C<credentials>, C<resource_map>,
C<resource_map_from_cluster> and C<with> parameters.

If C<kubeconfig> is provided without explicit C<server> or C<credentials>,
they are loaded automatically via L<Kubernetes::REST::Kubeconfig>. So are
they for a C<context> without C<kubeconfig>, from the default kubeconfig.
Either way a kubeconfig or context that cannot be resolved croaks with the
reason (a missing file, C<Context not found: ...>).

When running inside a Kubernetes pod (no C<kubeconfig> or C<server> set),
the service account token at
C</var/run/secrets/kubernetes.io/serviceaccount/token> is used
automatically for in-cluster authentication.

=head2 kubeconfig

Path to kubeconfig file. If provided, C<server> and C<credentials> are
extracted automatically (via L<Kubernetes::REST::Kubeconfig>).

=head2 context

Kubernetes context to use from the kubeconfig. Defaults to current-context.
Without L</kubeconfig> it is looked up in the default kubeconfig
(C<KUBECONFIG>, else F<~/.kube/config>); when it is not found there, or
there is no kubeconfig at all and no in-cluster service account either, the
constructor croaks with the reason.

=head2 resource_map

Optional. Custom resource map for short class names.

=head2 resource_map_from_cluster

Optional boolean, defaults to false. When true, L<Kubernetes::REST> reads the
cluster's discovery documents (C<GET /api>, C<GET /apis>) and, unless a
L</resource_map> is given, builds the resource map from them. Left to itself
it fetches them once, on first use, through its own synchronous HTTP backend,
not through this client's transport, so that first use blocks the loop.
Await L</discover> once at start-up to have them read through this client's
transport instead:

    my $kube = Net::Async::Kubernetes->new(
        kubeconfig                => "$ENV{HOME}/.kube/config",
        resource_map_from_cluster => 1,
    );
    $loop->add($kube);
    $kube->discover->get;

It also makes custom resources usable without a class of their own: a Kind
that no IO::K8s class or C<resource_map> entry serves, but which discovery
lists, resolves to L<IO::K8s::Unstructured>. Requests for it take the
resource's plural and scope from discovery, and a qualified
C<'group/version/Kind'> name stays in that group and version. An
L<IO::K8s::Unstructured> object handed to L</create>, L</update>,
L</ensure> or another object form is addressed the same way, by its own
C<kind> and C<apiVersion> -- without this option there is no discovery to
find its path in.

That group and version are the only ones such a request goes to. When the
cluster does not serve them, a qualified name is an unknown resource and an
object or manifest with that C<apiVersion> is refused, even if another group
or another version serves a Kind of the same name -- nothing is listed,
changed or deleted there instead.

A request for L<IO::K8s::Unstructured> that has no path -- without this
option, for the explicit class name C<IO::K8s::Unstructured> (a class name
carries no Kind), or for an object without C<kind> -- is refused before it
is sent, like any other bad argument: the L<Future> fails with the reason,
and L</update>, L</update_status>, L</ensure> and a watcher starting up
croak with it instead, as they do for their other argument errors.

=head2 with

Optional arrayref of L<IO::K8s> resource-map providers (CRD bundles),
passed on to L<Kubernetes::REST/with>, so their Kinds resolve to typed
classes -- in names, lists, watches and L</new_object>:

    my $kube = Net::Async::Kubernetes->new(
        kubeconfig => "$ENV{HOME}/.kube/config",
        with       => ['IO::K8s::GatewayAPI'],
    );
    my $gateways = $kube->list('Gateway', namespace => 'default')->get;

Defaults to C<[]>. See L<IO::K8s/with> for the accepted provider forms.

=head2 server

Returns the L<Kubernetes::REST::Server> instance. Croaks if neither C<server>
nor C<kubeconfig> was provided during initialization.

=head2 credentials

Returns the credentials object (typically L<Kubernetes::REST::AuthToken>).
Croaks if neither C<credentials> nor C<kubeconfig> was provided during
initialization.

=head2 rest

    my $rest = $kube->rest;

Returns the underlying lazily-built L<Kubernetes::REST> instance used for
request building and response processing. Exposed for advanced use -- most
callers want the higher-level CRUD methods instead. The private C<_rest>
accessor used throughout the internals returns this same cached instance.

=head2 new_object

    my $cm = $kube->new_object(ConfigMap =>
        metadata => { name => 'my-config' },
        data     => { key => 'value' },
    );

Builds a typed L<IO::K8s> object from a short class name (e.g. C<'Pod'>,
C<'ConfigMap'>) and either a hashref or a hash of attributes. Delegates to
L<Kubernetes::REST/new_object>. This is the public path for constructing the
objects passed to C<create> and C<update>.

=head2 expand_class

    my $full_class = $kube->expand_class('Pod');
    # Returns 'IO::K8s::Api::Core::V1::Pod'

Expands a short resource name (e.g., C<'Pod'>, C<'Deployment'>) to its full
IO::K8s class name. Delegates to L<Kubernetes::REST/expand_class>.

The name may also be qualified as C<'group/version/Kind'>, which resolves to
that exact API version instead of the historical default the bare Kind name
carries -- the two forms can and do point at different classes:

    $kube->expand_class('HorizontalPodAutoscaler');
    # 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler' (bare-name default)

    $kube->expand_class('autoscaling/v1/HorizontalPodAutoscaler');
    # 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler' (pinned to v1)

This qualified form is accepted anywhere a resource name is, including
C<list>, C<get>, and C<watcher>.

The result is a plain class name, without a C<+>. Handed back to a method
that resolves names again -- L</new_object>, L<IO::K8s/struct_to_object> --
a single-segment class of your own (C<'+Gizmo'> in the L</resource_map>,
returned as C<'Gizmo'>) reads as the Kind C<Gizmo> there. Prefix it with
C<+> when you do that yourself. The client's own methods already do, for the
manifests L</ensure> resolves and for every answer they inflate, a watch
event included -- whichever L<Kubernetes::REST> version is installed.

Croaks when the name cannot be resolved to an IO::K8s class -- a qualified
name no class serves, and equally a bare Kind no class ships for (C<'Bogus'>),
which L<Kubernetes::REST/expand_class> would hand back as a fabricated
C<IO::K8s::Bogus>. It also croaks when the name resolves to a class that
cannot serve as a resource, with the real cause rather than "unknown
resource": a class that does not load or compile (say, a typo in a
C<'+Class'> entry of L</resource_map>) croaks with its load error, and a
class without an C<api_version> of its own -- an IO::K8s helper such as
C<IO::K8s::List> that a bare C<'List'> lands on -- croaks as not being a
Kubernetes resource class. This is the synchronous counterpart of the
C<Future>-returning methods below, which report the same conditions as a
failed L<Future> with the same message.

=head2 discover

    $kube->discover->get;    # once, at start-up

Reads the cluster's discovery documents (C<GET /api>, C<GET /apis>) through
this client's own asynchronous transport and hands them to
L<Kubernetes::REST>, which then resolves names -- a Kind only the cluster
serves included (see L</resource_map_from_cluster>) -- and builds its
resource map from them without a request of its own. Returns a L<Future>
that resolves, with no value, once that is done.

With L</resource_map_from_cluster> on, await it once at start-up, before the
first request: otherwise L<Kubernetes::REST> reads discovery itself on first
use, through its synchronous HTTP backend, and that first use blocks the
loop. No other method calls C<discover> for you. Calling it again reads
discovery anew and replaces what was read before -- after installing a
CustomResourceDefinition, for example.

=over 4

=item * Without L</resource_map_from_cluster> there is no discovery to read:
the L<Future> is done at once and nothing is sent.

=item * A cluster older than Kubernetes 1.27 answers with legacy discovery,
which takes a further request per API group and version.
L<Kubernetes::REST> keeps nothing of it; the L<Future> is done all the same,
and discovery is read synchronously on first use, as without C<discover>.

=item * An error status (C<401>, C<403>, C<5xx>) fails the L<Future> as
described in L</ERRORS>, C<< ->fail($error, 'http', $response) >>. A request
that gets no response fails it the way the transport reports it, and a
document that cannot be read (not JSON) with the reason.

=back

=head2 list

    my $future = $kube->list('Pod', namespace => 'default');
    my $list = $future->get;
    my @pods = @{ $list->items };

    my $future = $kube->list('Pod', labelSelector => 'app=web');

List resources of the given type. Returns a L<Future> that resolves to an
L<IO::K8s::List>. Its C<items> accessor holds the ArrayRef of inflated
IO::K8s objects.

C<labelSelector> and C<fieldSelector> are sent as query parameters, so
filtering happens server-side rather than on the list that comes back.
Any other option -- a misspelt C<labelselector> would otherwise list every
object -- fails the L<Future> before a request is sent, naming the options
C<list> takes. So does an odd list of options, as C<Invalid arguments to
list()>: its last key would otherwise go out without a value.

Arguments:

=over 4

=item C<$short_class> - Resource type (e.g., C<'Pod'>, C<'Deployment'>), or a
qualified C<'group/version/Kind'> name to pin a specific API version -- see
L</expand_class>

=item C<%args> - Optional parameters: C<namespace>, C<labelSelector>,
C<fieldSelector>

=back

=head2 get

    my $future = $kube->get('Pod', 'nginx', namespace => 'default');
    my $pod = $future->get;

Get a single resource by name. Returns a L<Future> that resolves to an
inflated IO::K8s object. An option other than C<name> and C<namespace> fails
the L<Future> before a request is sent, and so does an odd list of options,
as C<Invalid arguments to get()>. A reference in place of the name -- a
manifest hashref, an IO::K8s object -- fails it as C<resource name must be a
string, got a HASH reference>, before it is stringified into the request path.

Arguments:

=over 4

=item C<$short_class> - Resource type (e.g., C<'Pod'>), or a qualified
C<'group/version/Kind'> name -- see L</expand_class>

=item C<$name> - Resource name (required)

=item C<%args> - Optional parameters: C<namespace>

=back

=head2 create

    my $future = $kube->create($pod_object);
    my $created = $future->get;

Create a resource from an IO::K8s object. Returns a L<Future> that resolves
to the created object with server-populated fields (C<resourceVersion>, etc.).

An object that is no Kubernetes resource -- an L<IO::K8s::List>, a nested
type such as a C<PodSpec> -- or anything that is not an IO::K8s object fails
the L<Future> before a request is sent.

Arguments:

=over 4

=item C<$object> - IO::K8s object instance (e.g., C<IO::K8s::Api::Core::V1::Pod>)

=back

=head2 update

    my $future = $kube->update($modified_pod);
    my $updated = $future->get;

Update an existing resource. The object must have C<metadata.name> (and
C<metadata.namespace> if namespaced). Returns a L<Future> that resolves to
the updated object.

A missing C<metadata> or C<metadata.name> croaks synchronously, and so does
an object that is no Kubernetes resource -- an L<IO::K8s::List>, a nested
type such as a C<PodSpec> -- or anything that is not an IO::K8s object.

Arguments:

=over 4

=item C<$object> - Modified IO::K8s object with updated fields

=back

=head2 update_status

    my $future = $kube->update_status($node);
    my $updated = $future->get;

Replace a resource's B<status> through the C</status> subresource. The whole
object is sent, as with L</update>, but the server only stores the C<status>
it carries and leaves C<spec> and C<metadata> untouched. Returns a L<Future>
that resolves to the updated object.

Needs a current C<resourceVersion> and fails with a 409 conflict if the
object changed on the server in the meantime. A missing C<metadata> or
C<metadata.name>, or an object that is no Kubernetes resource, croaks
synchronously, as with L</update>. Prefer
L</patch_status> when you are setting individual status fields.

Arguments:

=over 4

=item C<$object> - IO::K8s object with C<metadata.name> (and C<namespace> if
namespaced) and the desired C<status>

=back

=head2 patch

    # By class and name
    my $future = $kube->patch('Pod', 'nginx',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'prod' } } },
        type      => 'strategic',  # or 'merge', 'json'
    );

    # Or by object
    my $future = $kube->patch($pod_object,
        patch => { spec => { replicas => 3 } },
    );

Patch an existing resource. Returns a L<Future> that resolves to the patched
object. Bad arguments -- among them an object that is no Kubernetes
resource, such as an L<IO::K8s::List> or a nested C<PodSpec>, a plain
reference such as a manifest hashref in place of the resource name, an odd
list of options after the object or the name (C<Invalid arguments to
patch()>), and an option not listed below (in the object form C<name> and
C<namespace> come from the object and are refused as options too) -- fail
the L<Future> before a request is sent.

Arguments:

=over 4

=item C<$class_or_object> - Resource class name or IO::K8s object

=item C<name> - Resource name (required unless passing object)

=item C<namespace> - Namespace (if namespaced)

=item C<patch> - HashRef of changes to apply (required)

=item C<type> - Patch type: C<'strategic'> (default), C<'merge'>, or C<'json'>

=back

=head2 patch_status

    # By class and name
    my $future = $kube->patch_status('OCPNode', 'cp-1',
        namespace => 'ocp',
        patch     => { status => { phase => 'Ready' } },
    );

    # Or by object
    my $future = $kube->patch_status($node,
        patch => { status => { phase => 'Ready' } },
    );

Partially update a resource's B<status> through the C</status> subresource.
Once a CustomResourceDefinition declares C<subresources: { status: {} }>, the
API server drops the C<status> stanza from every write to the main endpoint
and still answers 2xx -- so a C<status> written via L</patch> or L</update>
is silently discarded. This method writes to C</status> instead.

Takes the same call forms and arguments as L</patch> (object, or class plus
name in either the shorthand or fully-keyed form), and refuses any other
option, and an odd list of options, the same way. The patch document is
sent unchanged and carries its own C<status> key.

The default patch type is C<merge>, not C<strategic> as in L</patch>: custom
resources reject strategic merge patch with a 415, and C<merge> works for
built-in kinds too. Pass C<type =E<gt> 'strategic'> explicitly to patch the
status of a built-in resource when you need array merge semantics.

Returns a L<Future> that resolves to the patched object; bad arguments, an
unknown patch C<type>, or a server error fail the Future, as with L</patch>.

Arguments:

=over 4

=item C<$class_or_object> - Resource class name or IO::K8s object

=item C<name> - Resource name (required unless passing object)

=item C<namespace> - Namespace (if namespaced)

=item C<patch> - HashRef with a C<status> key (or ArrayRef of operations when
C<type> is C<json>)

=item C<type> - Patch type: C<'merge'> (default), C<'strategic'>, or C<'json'>

=back

=head2 delete

    # By class and name
    my $future = $kube->delete('Pod', 'nginx', namespace => 'default');
    $future->get;

    # Or by object
    my $future = $kube->delete($pod_object);
    $future->get;

    # A Job together with its Pods
    $kube->delete('Job', 'nightly', namespace => 'default',
        propagationPolicy => 'Background')->get;
    $kube->delete($job, propagationPolicy => 'Foreground')->get;

Delete a resource. Returns a L<Future> that resolves to C<1> on success.
In the object form, an object without C<metadata.name>, one that is no
Kubernetes resource (an L<IO::K8s::List>, a nested C<PodSpec>), or a
reference that is not an IO::K8s object fails the L<Future>. In the class
form, a reference in place of the name -- C<delete('Pod', $manifest)> --
fails it as C<resource name must be a string, got a HASH reference>, before
it is stringified into the request path.

C<propagationPolicy> is sent as a query parameter and decides what happens
to the objects the deleted one owns: C<Background> deletes them after it,
C<Foreground> before it, C<Orphan> leaves them. Without it the API server
applies the resource's own default -- for a C<Job> that orphans its Pods.
Any other value, and any option C<delete> does not know (a misspelt
C<propagationPolicy> would otherwise be dropped silently), fails the
L<Future> before a request is sent, worded as L<Kubernetes::REST> words it:
C<Unknown propagationPolicy 'x' for delete() (use: Background, Foreground,
Orphan)>, or C<Unknown argument 'x' to delete() (allowed: ...)> naming the
first unknown option.

Arguments:

=over 4

=item C<$class_or_object> - Resource class name or IO::K8s object

=item C<$name> - Resource name (required unless passing object)

=item C<namespace> - Namespace (if namespaced; not in the object form, which
takes it from the object)

=item C<propagationPolicy> - C<'Background'>, C<'Foreground'> or C<'Orphan'>;
optional

=back

=head2 ensure

    my $future = $kube->ensure($pod);
    my $obj = $future->get;

    # or from a plain hashref (treated as a Kubernetes manifest):
    my $future = $kube->ensure({
        apiVersion => 'v1',
        kind       => 'Secret',
        metadata   => { name => 'foo', namespace => 'default' },
        stringData => { password => 'hunter2' },
    });

Idempotent create-or-update. GETs the object by kind/name/namespace: if it is
missing, creates it; if it exists, updates it at the server's
C<resourceVersion>, which this method writes back into the object passed in.
Returns a L<Future> that resolves to the resulting IO::K8s object.

Accepts a typed IO::K8s object or a plain hashref; a hashref must carry a
C<kind> field and uses manifest-style camelCase keys (C<stringData>, not
C<string_data>).

A hashref's C<apiVersion>, when present, selects the class: an
C<autoscaling/v1> HorizontalPodAutoscaler stays C<autoscaling/v1> and goes to
that endpoint, although the bare Kind resolves to C<autoscaling/v2>. A hashref
without C<apiVersion> (or with an empty one) resolves by its Kind alone, as
L</expand_class> does.

Handles the create/update race: a 409 on update (something else changed the
object between GET and PUT) refetches once and retries the update; a 409 on
create (something else created it between GET and POST) refetches it and
handles it like an object that existed from the start -- updated, with the
same one retry, or, for the two special cases below, returned unchanged or
deleted and recreated.

Two kinds get special handling because their spec is immutable after
creation: an existing core C<v1> C<PersistentVolumeClaim> is left unchanged,
and an existing C<batch/v1> C<Job> is left unchanged while it is active or has
succeeded, and deleted and recreated otherwise -- deleted with
C<propagationPolicy> C<Background>, so its Pods go with it instead of being
orphaned. Both are recognised by
apiVersion and Kind together -- the object's C<api_version> and C<kind> --
never by the class name. A custom resource that reuses one of these Kind
names in its own group is ensured like any other object, and so is a C<Job>
under any apiVersion other than C<batch/v1>.

Errors that are known before any request is made -- a hashref without
C<kind>, a value that is neither an object nor a hashref, an object that is
no Kubernetes resource (an L<IO::K8s::List>, a nested type such as a
C<PodSpec>), an object missing C<metadata>/C<metadata.name>, an unknown
C<kind>, a C<kind> whose class does
not load or is no resource class (see L</expand_class>), or an C<apiVersion>
that resolves to no known class (the message names both the Kind and the
C<apiVersion>) -- croak synchronously, as with L</update>. Anything that
goes wrong during the request flow itself fails the Future instead.

Arguments:

=over 4

=item C<$object> - IO::K8s object or hashref manifest (must have C<kind> if a
hashref)

=back

=head2 ensure_all

    my $future = $kube->ensure_all(@objects);
    my @results = $future->get;

Batch form of L</ensure>. Applies each object in order, one at a time --
object N+1 is only started once object N has resolved, so a later object may
depend on an earlier one (a Namespace before what lives in it). Returns a
L<Future> that resolves to the list of results in input order.

If any object fails -- including a croak from L</ensure>, which becomes a
failure here -- the Future fails and no later object is started.
C<ensure_all> itself never croaks synchronously.

Arguments:

=over 4

=item C<@objects> - IO::K8s objects or hashref manifests, as accepted by
L</ensure>

=back

=head2 ensure_only

    my $future = $kube->ensure_only(
        label      => 'app.kubernetes.io/component=queen',
        objects    => \@objects,
        kinds      => [qw(Role RoleBinding ClusterRoleBinding)],
        namespaces => ['default', 'kube-system', undef],
    );
    my @applied = $future->get;

Like L</ensure_all>, but also deletes anything matching the label selector in
the given kinds and namespaces that is not present in C<objects>. Use this
for resources where stale objects must not survive (e.g. RBAC). Croaks
synchronously if C<label> is missing, if C<propagationPolicy> is none of
the values L</delete> accepts, on any option not listed below -- a
C<namespace> meant as C<namespaces> would otherwise prune at cluster scope
only -- and on an odd list of options (C<Invalid arguments to
ensure_only()>), whose last key would otherwise be taken as given without a
value: a stray C<objects> would prune everything carrying the label.

Hashrefs in C<objects> are resolved as in L</ensure>, all of them before the
first request: one without C<kind> or with an C<apiVersion> no class serves
croaks, and nothing is applied or deleted.

Applies C<objects> via L</ensure_all>, then for each kind in C<kinds> and
each namespace in C<namespaces>, lists resources of that kind carrying the
label and deletes any that do not match one of the just-applied objects by
API group, Kind, namespace and name. Group and Kind are each object's own --
the group from its C<api_version>, the Kind from its C<kind> -- so a
qualified C<'group/version/Kind'> entry in C<kinds> still recognises the
objects it lists rather than deleting them. The same Kind name in another
group is another resource: with Istio's C<networking.istio.io> Gateway in
C<objects>, a labelled Gateway API C<gateway.networking.k8s.io> Gateway of
the same name and namespace is deleted. The version is not compared: an
object applied as C<autoscaling/v1> is kept when the listing goes through
C<autoscaling/v2>. A C<namespaces> entry of C<undef> scans cluster-scoped
resources; if C<namespaces> is omitted, only cluster-scoped resources are
scanned.

Stale objects are deleted with C<propagationPolicy> C<Background> unless
C<propagationPolicy> says otherwise, so a pruned Job or Deployment takes its
Pods with it; the API server's own default would leave a Job's Pods behind.

Pruning goes on past a failure, and says so. When a C<kinds> entry cannot be
listed in one namespace -- the API server rejects the request, the request
fails without a response, or the entry resolves to no usable class -- that
combination is skipped with a warning (C<carp>) naming the entry, the
namespace (or cluster scope) and the reason; anything stale there survives
this run. A 404 is silent: the cluster does not serve that Kind, so there is
nothing to prune. A delete that fails warns with the Kind, name, namespace
and reason, and the next object is tried; a 404 there means the object is
already gone and is silent too. A C<$SIG{__WARN__}> handler that dies while
the prune runs fails the returned L<Future> with the warning instead.

Returns a L<Future> that resolves to the list of applied objects (from
L</ensure_all>), whether or not the pruning was complete.

Arguments:

=over 4

=item C<label> - Label selector matching stale objects to delete (required)

=item C<objects> - ArrayRef of objects/hashrefs to apply, as for L</ensure_all>

=item C<kinds> - ArrayRef of resource kinds to scan for stale objects

=item C<namespaces> - ArrayRef of namespaces to scan, C<undef> for
cluster-scoped; defaults to cluster-scoped only

=item C<propagationPolicy> - How stale objects are deleted: C<'Background'>
(default), C<'Foreground'> or C<'Orphan'>, as for L</delete>

=back

=head2 log

    # One-shot mode (Future resolves to full text)
    my $text = $kube->log('Pod', 'my-pod',
        namespace => 'default',
        tailLines => 100,
    )->get;

    # Streaming mode (Future resolves when stream ends)
    $kube->log('Pod', 'my-pod',
        namespace => 'default',
        follow    => 1,
        on_line   => sub {
            my ($event) = @_;  # Kubernetes::REST::LogEvent
            say $event->line;
        },
    )->get;

Retrieve logs from a pod.

Without C<on_line>, returns a L<Future> that resolves to the full log text.

With C<on_line>, opens a streaming request and invokes the callback once per
line with L<Kubernetes::REST::LogEvent> objects. The returned L<Future>
resolves when the stream ends.

Besides C<name>, C<namespace> and C<on_line> it takes the options
C<container>, C<follow>, C<tailLines>, C<sinceSeconds>, C<sinceTime>,
C<timestamps>, C<previous> and C<limitBytes>, sent as query parameters. Any
other -- C<tail_lines> would otherwise fetch the whole log -- fails the
L<Future> before a request is sent.

=head2 port_forward

    my $f = $kube->port_forward('Pod', 'my-pod',
        namespace => 'default',
        ports     => [8080, 8443],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    );
    my $session = $f->get;

Create an async pod port-forward session request.

Returns a L<Future> that resolves to the duplex session object returned by the
transport backend. The default transport returns a
L<Net::Async::Kubernetes::PortForwardSession> object.

The session helper supports C<write_channel>, C<write_stdin>, C<resize>, and
C<close>.

C<on_open> receives the created session object.

C<on_frame> receives C<($channel, $payload)> where the first byte of each
binary websocket frame is decoded as Kubernetes channel id.

It takes C<name>, C<namespace>, C<ports> (one port or an arrayref of them,
required), C<subprotocol> (default C<v4.channel.k8s.io>) and the callbacks
C<on_open>, C<on_frame>, C<on_close> and C<on_error>. Any other option -- a
misspelt C<onFrame> would otherwise be dropped, a C<subresource> would even
land in the request path -- fails the L<Future> before a request is sent,
naming the options C<port_forward> takes.

=head2 exec

    my $f = $kube->exec('Pod', 'my-pod',
        namespace => 'default',
        command   => ['sh', '-c', 'id'],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    );
    my $session = $f->get;

Create an async pod exec session request.

Returns a L<Future> that resolves to the duplex session object returned by the
transport backend. The default transport returns a
L<Net::Async::Kubernetes::PortForwardSession> object.

The session helper supports C<write_channel>, C<write_stdin>, C<resize>, and
C<close>.

C<on_open> receives the created session object.

C<on_frame> receives C<($channel, $payload)> where the first byte of each
binary websocket frame is decoded as Kubernetes channel id.

Besides C<name>, C<namespace>, C<command> (a string or an arrayref,
required), C<subprotocol> and the callbacks it takes C<container>,
C<stdin>, C<stdout>, C<stderr> and C<tty>, sent as query parameters
(C<stdout> and C<stderr> default to true, the others to false). Any other
option -- a misspelt C<container> would otherwise run the command in the
pod's default container -- fails the L<Future> before a request is sent,
naming the options C<exec> takes.

=head2 attach

    my $f = $kube->attach('Pod', 'my-pod',
        namespace => 'default',
        container => 'app',
        stdin     => 1,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    );
    my $session = $f->get;

Create an async pod attach session request.

Returns a L<Future> that resolves to the duplex session object returned by the
transport backend. The default transport returns a
L<Net::Async::Kubernetes::PortForwardSession> object.

The session helper supports C<write_channel>, C<write_stdin>, C<resize>, and
C<close>.

C<on_open> receives the created session object.

C<on_frame> receives C<($channel, $payload)> where the first byte of each
binary websocket frame is decoded as Kubernetes channel id.

It takes C<name>, C<namespace>, C<container>, C<stdin>, C<stdout>,
C<stderr>, C<tty>, C<subprotocol> and the callbacks, as L</exec> does, but
no C<command>. Any other option, C<command> among them, fails the L<Future>
before a request is sent, naming the options C<attach> takes.

=head2 cp_to_pod

    my $f = $kube->cp_to_pod('Pod', 'my-pod',
        namespace => 'default',
        container => 'app',
        local     => '/tmp/local.txt',
        remote    => '/tmp/remote.txt',
    );
    my $result = $f->get;

Copy a single local file into a pod. Reads the entire local file into memory,
then runs C<sh -c 'head -c "$1" > "$2"'> inside the pod via C<exec()> and
streams the bytes over stdin.

This is a single-file copy, not a tar-based transfer: there is no recursive
directory copy, and the whole file is held in memory, so it is not suitable
for very large files.

Returns a L<Future> resolving to a hashref containing C<local>, C<remote>,
C<bytes>, C<stderr>, and C<status>.

It takes C<name>, C<namespace>, C<container>, C<local>, C<remote> and
C<chunk_size> (bytes per stdin write, default 65536). Any other option fails
the L<Future> before a request is sent, naming the options C<cp_to_pod>
takes.

=head2 cp_from_pod

    my $f = $kube->cp_from_pod('Pod', 'my-pod',
        namespace => 'default',
        container => 'app',
        remote    => '/tmp/remote.txt',
        local     => '/tmp/local.txt',
    );
    my $result = $f->get;

Copy a single file out of a pod. Runs C<cat $remote> inside the pod via
C<exec()>, buffers the entire stdout stream in memory, then writes it to the
local file.

This is a single-file copy, not a tar-based transfer: there is no recursive
directory copy, and the whole file is held in memory, so it is not suitable
for very large files.

Returns a L<Future> resolving to a hashref containing C<local>, C<remote>,
C<bytes>, C<stderr>, and C<status>.

It takes C<name>, C<namespace>, C<container>, C<remote> and C<local>. Any
other option -- C<chunk_size> belongs to L</cp_to_pod> only -- fails the
L<Future> before a request is sent, naming the options C<cp_from_pod>
takes.

=head2 watcher

    my $watcher = $kube->watcher('Pod',
        namespace      => 'default',
        label_selector => 'app=web',
        on_added       => sub { my ($pod) = @_; ... },
        on_modified    => sub { my ($pod) = @_; ... },
        on_deleted     => sub { my ($pod) = @_; ... },
    );

Create and register a L<Net::Async::Kubernetes::Watcher> for the specified
resource type. The watcher is added as a child notifier and will start
automatically when the parent is added to a loop.

Returns the watcher object. An odd list of parameters croaks, as
C<Invalid arguments to watcher()>, before the watcher is created -- as an
unknown parameter does.

Arguments:

=over 4

=item C<$resource> - Resource type to watch (e.g., C<'Pod'>, C<'Deployment'>)

=item C<%args> - Watcher parameters (C<namespace>, C<label_selector>, callbacks, etc.)

=back

See L<Net::Async::Kubernetes::Watcher> for all available parameters.

=head2 controller

    my $controller = $kube->controller(
        on_reconcile => sub {
            my ($ctx) = @_;
            ...
        },
    );

Create and register a L<Net::Async::Kubernetes::Controller> runtime bound to
this client. The controller is added as a child notifier and can register
resource watches, queue reconcile work, and patch object status.

Returns the controller object. An odd list of parameters croaks, as
C<Invalid arguments to controller()>, before the controller is created.

=head1 ERRORS

The C<Future>-returning methods report every failure through the returned
L<Future>:

=over 4

=item * Bad arguments -- an unknown resource, an object that is no
Kubernetes resource, a missing name, an unknown option -- fail it with a
message before any request is sent. L</expand_class>, L</update>,
L</update_status>, L</ensure> and a watcher that starts croak instead, as
each of them documents.

=item * A response the API server refuses (status 400 and up) fails it
following L<Future>'s convention for failure details:
C<< ->fail($error, 'http', $response) >>. C<$error> is exactly what
L<Kubernetes::REST/check_response> throws, a L<Kubernetes::REST::APIError>
object, which stringifies to the message
(C<Kubernetes API error (get Pod): 404 ...>).
C<$response> is the L<Kubernetes::REST::HTTPResponse>, whose C<status>
tells a C<404> from a C<409> without parsing the message:

    $kube->delete('Pod', 'web', namespace => 'default')->catch(http => sub {
        my ($error, $category, $response) = @_;
        return Future->done if $response->status == 404;   # already gone
        return Future->fail(@_);
    })->get;

L</ensure> and L</ensure_all> pass the failure of the request that failed
on in the same form.

=item * A request that gets no response at all (connection refused, a TLS
error) fails it the way the HTTP transport reports it.

=back

A L<Net::Async::Kubernetes::Watcher> reports failures to its C<on_error>
callback instead, with the HTTP status in the C<code> of the C<Status> it
passes.

=head1 SEE ALSO

L<Net::Async::Kubernetes::Watcher>, L<Net::Async::Kubernetes::Controller>,
L<Net::Async::Kubernetes::PortForwardSession>, L<Kubernetes::REST>,
L<IO::Async>, L<IO::K8s>, L<Net::Async::WebSocket::Client>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-kubernetes/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
