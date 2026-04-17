package Net::Async::Kubernetes;
# ABSTRACT: Async Kubernetes client for IO::Async
our $VERSION = '0.007';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw(croak);
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

    # Resolve server/credentials via Kubeconfig (handles kubeconfig files
    # and in-cluster service account auto-detection)
    if (!$self->{server}) {
        require Kubernetes::REST::Kubeconfig;
        my $kc = Kubernetes::REST::Kubeconfig->new(
            ($self->{kubeconfig} ? (kubeconfig_path => $self->{kubeconfig}) : ()),
            ($self->{context}    ? (context_name    => $self->{context})    : ()),
        );
        if ($self->{kubeconfig}) {
            # Explicit kubeconfig — must resolve or croak
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


sub server {
    my ($self) = @_;
    $self->{server} // croak "server or kubeconfig required";
}


sub credentials {
    my ($self) = @_;
    $self->{credentials} // croak "credentials or kubeconfig required";
}


# Lazy internal Kubernetes::REST for request building + response processing
sub _rest {
    my ($self) = @_;
    $self->{_rest} //= Kubernetes::REST->new(
        server      => $self->server,
        credentials => $self->credentials,
        resource_map_from_cluster => $self->resource_map_from_cluster,
        ($self->resource_map ? (resource_map => $self->resource_map) : ()),
    );
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

sub expand_class { shift->_rest->expand_class(@_) }


sub _add_to_loop {
    my ($self, $loop) = @_;
    $self->add_child($self->_http);
}

# ============================================================================
# ASYNC CRUD METHODS - return Futures
# ============================================================================

sub list {
    my ($self, $short_class, %args) = @_;

    my $rest = $self->_rest;
    my $class = $rest->expand_class($short_class);
    my $path = $rest->build_path($class, %args);
    my $req = $rest->prepare_request('GET', $path);

    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "list $short_class");
        return Future->done($rest->inflate_list($class, $response));
    });
}


sub get {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;
    my %args;
    if (@rest_args == 1) {
        $args{name} = $rest_args[0];
    } elsif (@rest_args >= 2 && $rest_args[0] !~ /^(name|namespace)$/) {
        $args{name} = shift @rest_args;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to get()");
    }

    my $class = $rest->expand_class($short_class);
    return Future->fail("name required for get") unless $args{name};

    my $path = $rest->build_path($class, %args);
    my $req = $rest->prepare_request('GET', $path);

    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "get $short_class");
        return Future->done($rest->inflate_object($class, $response));
    });
}


sub create {
    my ($self, $object) = @_;

    my $rest = $self->_rest;
    my $class = ref($object);
    my $namespace = $object->can('metadata') && $object->metadata
        ? $object->metadata->namespace
        : undef;

    my $path = $rest->build_path($class, namespace => $namespace);
    my $req = $rest->prepare_request('POST', $path, body => $object->TO_JSON);

    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "create " . ref($object));
        return Future->done($rest->inflate_object($class, $response));
    });
}


sub update {
    my ($self, $object) = @_;

    my $rest = $self->_rest;
    my $class = ref($object);
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my $path = $rest->build_path($class, name => $name, namespace => $namespace);
    my $req = $rest->prepare_request('PUT', $path, body => $object->TO_JSON);

    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "update " . ref($object));
        return Future->done($rest->inflate_object($class, $response));
    });
}


sub patch {
    my ($self, $class_or_object, @rest_args) = @_;

    my $rest = $self->_rest;
    my ($class, $name, $namespace, $patch, $patch_type);

    if (ref($class_or_object) && blessed($class_or_object)) {
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or return Future->fail("object must have metadata");
        $name = $metadata->name or return Future->fail("object must have metadata.name");
        $namespace = $metadata->namespace;
        my %args = @rest_args;
        $patch = $args{patch} // return Future->fail("patch requires 'patch' parameter");
        $patch_type = $args{type} // 'strategic';
    } else {
        my %args;
        if (@rest_args >= 1 && !ref($rest_args[0]) && $rest_args[0] !~ /^(name|namespace|patch|type)$/) {
            $args{name} = shift @rest_args;
            %args = (%args, @rest_args);
        } elsif (@rest_args % 2 == 0) {
            %args = @rest_args;
        } else {
            return Future->fail("Invalid arguments to patch()");
        }

        $class = $rest->expand_class($class_or_object);
        $name = $args{name} or return Future->fail("name required for patch");
        $namespace = $args{namespace};
        $patch = $args{patch} // return Future->fail("patch requires 'patch' parameter");
        $patch_type = $args{type} // 'strategic';
    }

    my %patch_types = (
        strategic => 'application/strategic-merge-patch+json',
        merge     => 'application/merge-patch+json',
        json      => 'application/json-patch+json',
    );
    my $content_type = $patch_types{$patch_type}
        // return Future->fail("Unknown patch type '$patch_type'");

    my $path = $rest->build_path($class, name => $name, namespace => $namespace);
    my $req = $rest->prepare_request('PATCH', $path,
        body => $patch, content_type => $content_type);

    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "patch $class");
        return Future->done($rest->inflate_object($class, $response));
    });
}


sub delete {
    my ($self, $class_or_object, @rest_args) = @_;

    my $rest = $self->_rest;
    my ($class, $name, $namespace);

    if (ref($class_or_object)) {
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or return Future->fail("object must have metadata");
        $name = $metadata->name or return Future->fail("object must have metadata.name");
        $namespace = $metadata->namespace;
    } else {
        my %args;
        if (@rest_args == 1) {
            $args{name} = $rest_args[0];
        } elsif (@rest_args >= 2 && $rest_args[0] !~ /^(name|namespace)$/) {
            $args{name} = shift @rest_args;
            %args = (%args, @rest_args);
        } elsif (@rest_args % 2 == 0) {
            %args = @rest_args;
        } else {
            return Future->fail("Invalid arguments to delete()");
        }

        $class = $rest->expand_class($class_or_object);
        $name = $args{name} or return Future->fail("name required for delete");
        $namespace = $args{namespace};
    }

    my $path = $rest->build_path($class, name => $name, namespace => $namespace);
    my $req = $rest->prepare_request('DELETE', $path);

    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "delete $class");
        return Future->done(1);
    });
}


sub log {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;
    my %args;

    # Support: log('Pod', 'name', ...) and log('Pod', name => 'name', ...)
    if (@rest_args >= 1
        && !ref($rest_args[0])
        && $rest_args[0] !~ /^(name|namespace|container|follow|tailLines|sinceSeconds|sinceTime|timestamps|previous|limitBytes|on_line)$/
    ) {
        $args{name} = shift @rest_args;
        return Future->fail("Invalid arguments to log()") if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to log()");
    }

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

    my $class = $rest->expand_class($short_class);
    my $path = $rest->build_path($class, %args) . '/log';

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
            $rest->check_response($response, "log $short_class");
            if (length $buffer) {
                $on_line->(Kubernetes::REST::LogEvent->new(line => $buffer));
            }
            return Future->done(undef);
        });
    }

    my $req = $rest->prepare_request('GET', $path,
        %params ? (parameters => \%params) : (),
    );
    return $self->_do_request($req)->then(sub {
        my ($response) = @_;
        $rest->check_response($response, "log $short_class");
        return Future->done($response->content);
    });
}


sub port_forward {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;
    my %args;

    # Support: port_forward('Pod', 'name', ...) and port_forward('Pod', name => 'name', ...)
    if (@rest_args >= 1
        && !ref($rest_args[0])
        && $rest_args[0] !~ /^(name|namespace|ports|subprotocol|on_open|on_frame|on_close|on_error)$/
    ) {
        $args{name} = shift @rest_args;
        return Future->fail("Invalid arguments to port_forward()") if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to port_forward()");
    }

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

    my $class = $rest->expand_class($short_class);
    my $path = $rest->build_path($class, %args) . '/portforward';

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
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}


sub exec {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;
    my %args;

    # Support: exec('Pod', 'name', ...) and exec('Pod', name => 'name', ...)
    if (@rest_args >= 1
        && !ref($rest_args[0])
        && $rest_args[0] !~ /^(name|namespace|command|container|stdin|stdout|stderr|tty|subprotocol|on_open|on_frame|on_close|on_error)$/
    ) {
        $args{name} = shift @rest_args;
        return Future->fail("Invalid arguments to exec()") if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to exec()");
    }

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

    my $class = $rest->expand_class($short_class);
    my $path = $rest->build_path($class, %args) . '/exec';

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
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}


sub attach {
    my ($self, $short_class, @rest_args) = @_;

    my $rest = $self->_rest;
    my %args;

    # Support: attach('Pod', 'name', ...) and attach('Pod', name => 'name', ...)
    if (@rest_args >= 1
        && !ref($rest_args[0])
        && $rest_args[0] !~ /^(name|namespace|container|stdin|stdout|stderr|tty|subprotocol|on_open|on_frame|on_close|on_error)$/
    ) {
        $args{name} = shift @rest_args;
        return Future->fail("Invalid arguments to attach()") if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to attach()");
    }

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

    my $class = $rest->expand_class($short_class);
    my $path = $rest->build_path($class, %args) . '/attach';

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

    my %args;
    if (@rest_args >= 1
        && !ref($rest_args[0])
        && $rest_args[0] !~ /^(name|namespace|container|local|remote|chunk_size)$/
    ) {
        $args{name} = shift @rest_args;
        return Future->fail("Invalid arguments to cp_to_pod()") if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to cp_to_pod()");
    }

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

    my %args;
    if (@rest_args >= 1
        && !ref($rest_args[0])
        && $rest_args[0] !~ /^(name|namespace|container|local|remote)$/
    ) {
        $args{name} = shift @rest_args;
        return Future->fail("Invalid arguments to cp_from_pod()") if @rest_args % 2;
        %args = (%args, @rest_args);
    } elsif (@rest_args % 2 == 0) {
        %args = @rest_args;
    } else {
        return Future->fail("Invalid arguments to cp_from_pod()");
    }

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
    my ($self, $resource, %args) = @_;

    require Net::Async::Kubernetes::Watcher;

    my $watcher = Net::Async::Kubernetes::Watcher->new(
        kube     => $self,
        resource => $resource,
        %args,
    );

    $self->add_child($watcher);
    return $watcher;
}

sub controller {
    my ($self, %args) = @_;

    require Net::Async::Kubernetes::Controller;

    my $controller = Net::Async::Kubernetes::Controller->new(
        kube => $self,
        %args,
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

sub _do_streaming_request {
    my ($self, $req, $on_chunk) = @_;

    my $uri = URI->new($req->url);

    return $self->_http->do_request(
        method  => $req->method,
        uri     => $uri,
        headers => $req->headers,
        on_header => sub {
            my ($response) = @_;
            return sub {
                my ($chunk) = @_;
                if (defined $chunk) {
                    $on_chunk->($chunk);
                }
            };
        },
        $self->_ssl_options,
    )->then(sub {
        my ($response) = @_;
        return Future->done(Kubernetes::REST::HTTPResponse->new(
            status  => $response->code,
            content => '',
        ));
    });
}

sub _do_duplex_request {
    my ($self, $req, %callbacks) = @_;
    my $loop = eval { $self->loop };
    return Future->fail("port_forward requires Net::Async::Kubernetes to be added to an IO::Async::Loop")
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

package Net::Async::Kubernetes::PortForwardSession;

use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    croak "ws_client required" unless $args{ws_client};
    return bless \%args, $class;
}

sub ws_client { $_[0]->{ws_client} }

sub write_channel {
    my ($self, $channel, $payload) = @_;

    croak "channel required for write_channel" unless defined $channel;
    croak "invalid channel '$channel' for write_channel"
        unless $channel =~ /^\d+$/ && $channel >= 0 && $channel <= 255;

    $payload = '' unless defined $payload;
    croak "payload must be a plain string for write_channel" if ref($payload);

    return $self->ws_client->send_binary_frame(chr($channel) . $payload);
}

sub write_stdin {
    my ($self, $payload) = @_;
    return $self->write_channel(0, $payload);
}

{
    no warnings 'once';
    *write = \&write_channel;
    *stdin = \&write_stdin;
}

sub resize {
    my ($self, %args) = @_;

    my $width  = exists($args{width})  ? $args{width}  : $args{cols};
    my $height = exists($args{height}) ? $args{height} : $args{rows};

    croak "width required for resize" unless defined $width;
    croak "height required for resize" unless defined $height;
    croak "invalid width '$width' for resize"
        unless $width =~ /^\d+$/ && $width > 0;
    croak "invalid height '$height' for resize"
        unless $height =~ /^\d+$/ && $height > 0;

    my $payload = sprintf('{"Width":%d,"Height":%d}', $width, $height);
    return $self->write_channel(4, $payload);
}

sub close {
    my ($self, %args) = @_;
    my $code = $args{code};
    my $payload = exists $args{payload} ? $args{payload} : '';

    croak "payload must be a plain string for close" if ref($payload);
    croak "invalid websocket close code '$code'"
        if defined($code) && ($code !~ /^\d+$/ || $code < 1000 || $code > 4999);

    my $close_payload = defined($code) ? pack('n', $code) . $payload : $payload;
    my $ret = $self->ws_client->send_close_frame($close_payload);
    $self->ws_client->close_when_empty if $self->ws_client->can('close_when_empty');
    return $ret;
}

package Net::Async::Kubernetes;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Kubernetes - Async Kubernetes client for IO::Async

=head1 VERSION

version 0.007

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
and C<resource_map_from_cluster> parameters.

If C<kubeconfig> is provided without explicit C<server> or C<credentials>,
they are loaded automatically via L<Kubernetes::REST::Kubeconfig>.

When running inside a Kubernetes pod (no C<kubeconfig> or C<server> set),
the service account token at
C</var/run/secrets/kubernetes.io/serviceaccount/token> is used
automatically for in-cluster authentication.

=head2 kubeconfig

Path to kubeconfig file. If provided, C<server> and C<credentials> are
extracted automatically (via L<Kubernetes::REST::Kubeconfig>).

=head2 context

Kubernetes context to use from the kubeconfig. Defaults to current-context.

=head2 resource_map

Optional. Custom resource map for short class names.

=head2 resource_map_from_cluster

Optional boolean. Load resource map from cluster OpenAPI spec.
Defaults to false.

=head2 server

Returns the L<Kubernetes::REST::Server> instance. Croaks if neither C<server>
nor C<kubeconfig> was provided during initialization.

=head2 credentials

Returns the credentials object (typically L<Kubernetes::REST::AuthToken>).
Croaks if neither C<credentials> nor C<kubeconfig> was provided during
initialization.

=head2 expand_class

    my $full_class = $kube->expand_class('Pod');
    # Returns 'IO::K8s::Api::Core::V1::Pod'

Expands a short resource name (e.g., C<'Pod'>, C<'Deployment'>) to its full
IO::K8s class name. Delegates to L<Kubernetes::REST/expand_class>.

=head2 list

    my $future = $kube->list('Pod', namespace => 'default');
    my $pods = $future->get;

List resources of the given type. Returns a L<Future> that resolves to an
ArrayRef of inflated IO::K8s objects.

Arguments:

=over 4

=item C<$short_class> - Resource type (e.g., C<'Pod'>, C<'Deployment'>)

=item C<%args> - Optional parameters (C<namespace>, etc.)

=back

=head2 get

    my $future = $kube->get('Pod', 'nginx', namespace => 'default');
    my $pod = $future->get;

Get a single resource by name. Returns a L<Future> that resolves to an
inflated IO::K8s object.

Arguments:

=over 4

=item C<$short_class> - Resource type (e.g., C<'Pod'>)

=item C<$name> - Resource name (required)

=item C<%args> - Optional parameters (C<namespace>, etc.)

=back

=head2 create

    my $future = $kube->create($pod_object);
    my $created = $future->get;

Create a resource from an IO::K8s object. Returns a L<Future> that resolves
to the created object with server-populated fields (C<resourceVersion>, etc.).

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

Arguments:

=over 4

=item C<$object> - Modified IO::K8s object with updated fields

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
object.

Arguments:

=over 4

=item C<$class_or_object> - Resource class name or IO::K8s object

=item C<name> - Resource name (required unless passing object)

=item C<namespace> - Namespace (if namespaced)

=item C<patch> - HashRef of changes to apply (required)

=item C<type> - Patch type: C<'strategic'> (default), C<'merge'>, or C<'json'>

=back

=head2 delete

    # By class and name
    my $future = $kube->delete('Pod', 'nginx', namespace => 'default');
    $future->get;

    # Or by object
    my $future = $kube->delete($pod_object);
    $future->get;

Delete a resource. Returns a L<Future> that resolves to C<1> on success.

Arguments:

=over 4

=item C<$class_or_object> - Resource class name or IO::K8s object

=item C<$name> - Resource name (required unless passing object)

=item C<%args> - Optional parameters (C<namespace>, etc.)

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

=head2 cp_to_pod

    my $f = $kube->cp_to_pod('Pod', 'my-pod',
        namespace => 'default',
        container => 'app',
        local     => '/tmp/local.txt',
        remote    => '/tmp/remote.txt',
    );
    my $result = $f->get;

Copy a single local file into a pod using C<exec()> and stdin streaming.

Returns a L<Future> resolving to a hashref containing C<local>, C<remote>,
C<bytes>, C<stderr>, and C<status>.

=head2 cp_from_pod

    my $f = $kube->cp_from_pod('Pod', 'my-pod',
        namespace => 'default',
        container => 'app',
        remote    => '/tmp/remote.txt',
        local     => '/tmp/local.txt',
    );
    my $result = $f->get;

Copy a single file from a pod using C<exec()> and stdout streaming.

Returns a L<Future> resolving to a hashref containing C<local>, C<remote>,
C<bytes>, C<stderr>, and C<status>.

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

Returns the watcher object.

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

Returns the controller object.

=head1 NAME

Net::Async::Kubernetes - Async Kubernetes client for IO::Async

=head1 SEE ALSO

L<Net::Async::Kubernetes::Watcher>, L<Kubernetes::REST>, L<IO::Async>,
L<IO::K8s>, L<Net::Async::WebSocket::Client>

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
