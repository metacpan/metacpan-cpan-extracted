package Store::CouchDB;

use Moo;

# ABSTRACT: Store::CouchDB - a simple CouchDB driver

our $VERSION = '4.3'; # VERSION

use MooX::Types::MooseLike::Base qw(:all);
use experimental 'smartmatch';
use JSON;
use LWP::Protocol::Net::Curl;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use URI::Escape;
use Carp;
use Data::Dump 'dump';

# the following GET parameter keys have to be JSON encoded according to the
# couchDB API documentation. http://docs.couchdb.org/en/latest/api/
my @JSON_KEYS = qw(
    doc_ids
    key
    keys
    startkey
    start_key
    endkey
    end_key
);


has 'debug' => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 },
    lazy    => 1,
);


has 'host' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => sub { 'localhost' },
);


has 'port' => (
    is       => 'rw',
    isa      => Int,
    required => 1,
    default  => sub { 5984 },
);


has 'ssl' => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 },
    lazy    => 1,
);


has 'db' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_db',
);


has 'user' => (
    is  => 'rw',
    isa => Str,
);


has 'pass' => (
    is  => 'rw',
    isa => Str,
);


has 'method' => (
    is       => 'rw',
    required => 1,
    default  => sub { 'GET' },
);


has 'error' => (
    is        => 'rw',
    predicate => 'has_error',
    clearer   => 'clear_error',
);


has 'purge_limit' => (
    is      => 'rw',
    isa     => Int,
    default => sub { 5000 },
);


has 'timeout' => (
    is      => 'rw',
    isa     => Int,
    default => sub { 30 },
);


has 'json' => (
    is => 'rw',
    isa =>
        sub { JSON->new->utf8->allow_nonref->allow_blessed->convert_blessed },
    default => sub {
        JSON->new->utf8->allow_nonref->allow_blessed->convert_blessed;
    },
);


has 'agent' => (
    is       => 'rw',
    lazy     => 1,
    required => 1,
    builder  => '_build_agent',
);

sub _build_agent {
    my ($self) = @_;

    return LWP::UserAgent->new(
        agent      => __PACKAGE__ . $Store::CouchDB::VERSION,
        timeout    => $self->timeout,
        keep_alive => 1,
    );
}


sub get_doc {
    my ($self, $data) = @_;

    unless (ref $data eq 'HASH') {
        $data = { id => $data };
    }

    $self->_check_db($data);

    unless ($data->{id}) {
        carp 'Document ID not defined';
        return;
    }

    my $path = $self->db . '/' . $data->{id};
    my $rev;
    $rev = 'rev=' . $data->{rev} if (exists $data->{rev} and $data->{rev});
    my $params = $self->_uri_encode($data->{opts});
    if ($rev or $params) {
        $path .= '?';
        $path .= $rev . '&' if $rev;
        $path .= $params . '&' if $params;
        chop $path;
    }

    $self->method('GET');

    return $self->_call($path);
}


sub head_doc {
    my ($self, $data) = @_;

    unless (ref $data eq 'HASH') {
        $data = { id => $data };
    }

    $self->_check_db($data);

    unless ($data->{id}) {
        carp 'Document ID not defined';
        return;
    }

    my $path = $self->db . '/' . $data->{id};

    $self->method('HEAD');
    my $rev = $self->_call($path);

    $rev =~ s/"//g if $rev;

    return $rev;
}


sub all_docs {
    my ($self, $data) = @_;

    $self->_check_db($data);

    my $path   = $self->db . '/_all_docs';
    my $params = $self->_uri_encode($data);
    $path .= '?' . $params if $params;

    $self->method('GET');
    my $res = $self->_call($path);

    return
            unless exists $res->{rows}
        and ref $res->{rows} eq 'ARRAY'
        and $res->{rows}->[0];

    return @{ $res->{rows} };
}


sub get_design_docs {
    my ($self, $data) = @_;

    $self->_check_db($data);

    my $path = $self->db
        . '/_all_docs?descending=true&startkey="_design0"&endkey="_design"';
    my $params = $self->_uri_encode($data);
    $path .= '&' . $params if $params;

    $self->method('GET');
    my $res = $self->_call($path);

    return
            unless exists $res->{rows}
        and ref $res->{rows} eq 'ARRAY'
        and $res->{rows}->[0];

    return @{ $res->{rows} }
        if (ref $data eq 'HASH' and $data->{include_docs});

    my @design;
    foreach my $design (@{ $res->{rows} }) {
        my (undef, $name) = split(/\//, $design->{key}, 2);
        push(@design, $name);
    }

    return @design;
}


sub put_doc {
    my ($self, $data) = @_;

    unless (exists $data->{doc} and ref $data->{doc} eq 'HASH') {
        carp "Document not defined";
        return;
    }

    $self->_check_db($data);

    my $path;
    if (exists $data->{doc}->{_id} and defined $data->{doc}->{_id}) {
        $self->method('PUT');
        $path = $self->db . '/' . $data->{doc}->{_id};
    }
    else {
        $self->method('POST');
        $path = $self->db;
    }

    my $params = $self->_uri_encode($data->{opts});
    $path .= '?' . $params if $params;
    my $res = $self->_call($path, undef, $data->{doc});

    # update revision in original doc for convenience
    $data->{doc}->{_rev} = $res->{rev} if exists $res->{rev};

    return ($res->{id}, $res->{rev}) if wantarray;
    return $res->{id};
}


sub del_doc {
    my ($self, $data) = @_;

    unless (ref $data eq 'HASH') {
        $data = { id => $data };
    }

    my $id  = $data->{id}  || $data->{_id};
    my $rev = $data->{rev} || $data->{_rev};

    unless ($id) {
        carp 'Document ID not defined';
        return;
    }

    $self->_check_db($data);

    # get doc revision if missing
    unless ($rev) {
        $rev = $self->head_doc($id);
    }

    # stop if doc doesn't exist
    unless ($rev) {
        carp "Document does not exist";
        return;
    }

    my $path   = $self->db . '/' . $id . '?rev=' . $rev;
    my $params = $self->_uri_encode($data->{opts});
    $path .= $params if $params;

    $self->method('DELETE');
    my $res = $self->_call($path);

    return ($res->{id}, $res->{rev}) if wantarray;
    return $res->{rev};
}


sub update_doc {
    my ($self, $data) = @_;

    unless (ref $data eq 'HASH'
        and exists $data->{doc}
        and ref $data->{doc} eq 'HASH')
    {
        carp "Document not defined";
        return;
    }

    unless (exists $data->{doc}->{_id} and defined $data->{doc}->{_id}) {
        carp "Document ID not defined";
        return;
    }

    unless (exists $data->{doc}->{_rev} and defined $data->{doc}->{_rev}) {
        carp "Document revision not defined";
        return;
    }

    $self->_check_db($data);

    my $rev = $self->head_doc($data->{doc}->{_id});
    unless ($rev) {
        carp "Document does not exist";
        return;
    }

    return $self->put_doc($data);
}


sub copy_doc {
    my ($self, $data) = @_;

    unless (ref $data eq 'HASH') {
        $data = { id => $data };
    }

    unless ($data->{id}) {
        carp "Document ID not defined";
        return;
    }

    # as long as CouchDB does not support automatic document name creation
    # for the copy command we copy the ugly way ...
    my $doc = $self->get_doc($data);

    unless ($doc) {
        carp "Document does not exist";
        return;
    }

    delete $doc->{_id};
    delete $doc->{_rev};

    return $self->put_doc({ doc => $doc });
}


sub show_doc {
    my ($self, $data) = @_;

    $self->_check_db($data);

    unless ($data->{show}) {
        carp 'show not defined';
        return;
    }

    my $path = $self->_make_path($data);

    $self->method('GET');

    return $self->_call($path);
}


sub get_view {
    my ($self, $data) = @_;

    unless ($data->{view}) {
        carp "View not defined";
        return;
    }

    $self->_check_db($data);

    my $path = $self->_make_path($data);
    $self->method('GET');
    my $res = $self->_call($path, 'accept_stale');

    # fallback lookup for broken data consistency due to the way earlier
    # versions of this module where handling (or not) input data that had been
    # stringified by dumpers or otherwise internally
    # e.g. numbers were stored as strings which will be used as keys eventually
    unless ($res->{rows}->[0]) {
        $path = $self->_make_path($data, 'compat');
        $res = $self->_call($path, 'accept_stale');
    }

    return unless $res->{rows}->[0];

    my $c      = 0;
    my $result = {};
    foreach my $doc (@{ $res->{rows} }) {
        if ($doc->{doc}) {
            $result->{ $doc->{key} || $c } = $doc->{doc};
        }
        else {
            next unless exists $doc->{value};
            if (ref $doc->{key} eq 'ARRAY') {
                $self->_hash($result, $doc->{value}, @{ $doc->{key} });
            }
            else {
                # TODO debug why this crashes from time to time
                #$doc->{value}->{id} = $doc->{id};
                $result->{ $doc->{key} || $c } = $doc->{value};
            }
        }
        $c++;
    }

    return $result;
}


sub get_post_view {
    my ($self, $data) = @_;

    unless ($data->{view}) {
        carp 'View not defined';
        return;
    }
    unless ($data->{opts}) {
        carp 'No options defined - use "get_view" instead';
        return;
    }

    $self->_check_db($data);

    my $opts;
    if ($data->{opts}) {
        $opts = delete $data->{opts};
    }

    my $path = $self->_make_path($data);
    $self->method('POST');
    my $res = $self->_call($path, 'accept_stale', $opts);

    my $result;
    foreach my $doc (@{ $res->{rows} }) {
        next unless exists $doc->{value};
        $doc->{value}->{id} = $doc->{id};
        $result->{ $doc->{key} } = $doc->{value};
    }

    return $result;
}


sub get_view_array {
    my ($self, $data) = @_;

    unless ($data->{view}) {
        carp 'View not defined';
        return;
    }

    # this is stupid behaviour where the result values are hashrefs we skip the
    # keys. with this flag it can be turned off without affecting the default
    my $parse_value_hash = 1;
    if (exists $data->{do_not_parse_result}) {
        $parse_value_hash = 0 if $data->{do_not_parse_result};
        delete $data->{do_not_parse_result};
    }

    $self->_check_db($data);

    my $path = $self->_make_path($data);
    $self->method('GET');
    my $res = $self->_call($path, 'accept_stale');

    # fallback lookup for broken data consistency due to the way earlier
    # versions of this module where handling (or not) input data that had been
    # stringified by dumpers or otherwise internally
    # e.g. numbers were stored as strings which will be used as keys eventually
    unless ($res->{rows}->[0]) {
        $path = $self->_make_path($data, 'compat');
        $res = $self->_call($path, 'accept_stale');
    }

    my @result;
    foreach my $doc (@{ $res->{rows} }) {
        if ($doc->{doc}) {
            push(@result, $doc->{doc});
        }
        else {
            next unless exists $doc->{value};
            if (ref($doc->{value}) eq 'HASH' and $parse_value_hash) {
                $doc->{value}->{id} = $doc->{id}
                    unless (exists $data->{opts}
                    and ref($data->{opts}) eq 'HASH'
                    and exists $data->{opts}->{reduce}
                    and $data->{opts}->{reduce} eq 'true');
                push(@result, $doc->{value});
            }
            else {
                push(@result, $doc);
            }
        }
    }

    return @result;
}


sub get_array_view {
    my ($self, $data) = @_;
    return [ $self->get_view_array($data) ];
}


sub list_view {
    my ($self, $data) = @_;

    unless ($data->{list}) {
        carp "List not defined";
        return;
    }

    unless ($data->{view}) {
        carp "View not defined";
        return;
    }

    $self->_check_db($data);

    my $path = $self->_make_path($data);

    $self->method('GET');

    return $self->_call($path, 'accept_stale');
}


sub changes {
    my ($self, $data) = @_;

    $self->_check_db($data);

    $self->method('GET');

    my $path   = $self->db . '/_changes';
    my $params = $self->_uri_encode($data);
    $path .= '?' . $params if $params;
    my $res = $self->_call($path);

    return $res;
}


sub purge {
    my ($self, $data) = @_;

    $self->_check_db($data);

    my $path = $self->db . '/_changes?limit=' . $self->purge_limit . '&since=0';
    $self->method('GET');
    my $res = $self->_call($path);

    return unless $res->{results}->[0];

    my @del;
    my $resp;

    $self->method('POST');
    foreach my $_del (@{ $res->{results} }) {
        next
            unless (exists $_del->{deleted}
            and ($_del->{deleted} eq 'true' or $_del->{deleted} == 1));

        my $opts = { $_del->{id} => [ $_del->{changes}->[0]->{rev} ], };
        $resp->{ $_del->{seq} } =
            $self->_call($self->db . '/_purge', undef, $opts);
    }

    return $resp;
}


sub compact {
    my ($self, $data) = @_;

    $self->_check_db($data);

    my $res;
    if ($data->{purge}) {
        $res->{purge} = $self->purge();
    }

    if ($data->{view_compact}) {
        $self->method('POST');
        $res->{view_compact} = $self->_call($self->db . '/_view_cleanup');
        my @design = $self->get_design_docs();
        $self->method('POST');
        foreach my $doc (@design) {
            $res->{ $doc . '_compact' } =
                $self->_call($self->db . '/_compact/' . $doc);
        }
    }

    $self->method('POST');
    $res->{compact} = $self->_call($self->db . '/_compact');

    return $res;
}


sub put_file {
    my ($self, $data) = @_;

    unless ($data->{file}) {
        carp 'File content not defined';
        return;
    }
    unless ($data->{filename}) {
        carp 'File name not defined';
        return;
    }

    $self->_check_db($data);

    my $id  = $data->{id}  || $data->{doc}->{_id};
    my $rev = $data->{rev} || $data->{doc}->{_rev};

    if (!$rev && $id) {
        $rev = $self->head_doc($id);
        $self->_log("put_file(): rev $rev") if $self->debug;
    }

    # create a new doc if required
    ($id, $rev) = $self->put_doc({ doc => {} }) unless $id;

    my $path = $self->db . '/' . $id . '/' . $data->{filename} . '?rev=' . $rev;

    $self->method('PUT');
    $data->{content_type} ||= 'text/plain';
    my $res = $self->_call($path, undef, $data->{file}, $data->{content_type});

    return ($res->{id}, $res->{rev}) if wantarray;
    return $res->{id};
}


sub get_file {
    my ($self, $data) = @_;

    $self->_check_db($data);

    unless ($data->{id}) {
        carp "Document ID not defined";
        return;
    }
    unless ($data->{filename}) {
        carp "File name not defined";
        return;
    }

    my $path = join('/', $self->db, $data->{id}, $data->{filename});

    $self->method('GET');

    return $self->_call($path);
}


sub del_file {
    my ($self, $data) = @_;

    unless ($data->{id}) {
        carp "Document ID not defined";
        return;
    }
    unless ($data->{filename}) {
        carp 'File name not defined';
        return;
    }

    $self->_check_db($data);

    my $id  = $data->{id};
    my $rev = $data->{rev};

    if ($id && !$rev) {
        $rev = $self->head_doc($id);
        $self->_log("delete_file(): rev $rev") if $self->debug;
    }

    my $path = $self->db . '/' . $id . '/' . $data->{filename} . '?rev=' . $rev;
    $self->method('DELETE');
    my $res = $self->_call($path);

    return ($res->{id}, $res->{rev}) if wantarray;
    return $res->{id};
}


sub config {
    my ($self, $data) = @_;

    foreach my $key (keys %{$data}) {
        $self->$key($data->{$key}) or confess "$key not defined as property!";
    }
    return $self;
}


sub create_db {
    my ($self, $db) = @_;

    if ($db) {
        $self->db($db);
    }

    $self->method('PUT');
    my $res = $self->_call($self->db);

    return $res;
}


sub delete_db {
    my ($self, $db) = @_;

    if ($db) {
        $self->db($db);
    }

    $self->method('DELETE');
    my $res = $self->_call($self->db);

    return $res;
}


sub all_dbs {
    my ($self) = @_;

    $self->method('GET');
    my $res = $self->_call('_all_dbs');

    return @{ $res || [] };
}

sub _check_db {
    my ($self, $data) = @_;

    if (    ref $data eq 'HASH'
        and exists $data->{dbname}
        and defined $data->{dbname})
    {
        $self->db($data->{dbname});
        return;
    }

    unless ($self->has_db) {
        carp 'database not defined! you must set $sc->db("some_database")';
        return;
    }

    return;
}

sub _uri_encode {
    my ($self, $options, $compat) = @_;

    return unless (ref $options eq 'HASH');

    # make sure stringified keys and values return their original state
    # because otherwise JSON will encode numbers as strings
    my $opts = eval dump $options;    ## no critic

    my $path = '';
    foreach my $key (keys %$opts) {
        my $value = $opts->{$key};

        if ($key ~~ @JSON_KEYS) {

            # backwards compatibility with key, startkey, endkey as strings
            $value .= '' if ($compat && !ref($value));

            # only JSON encode URI parameter value if necessary and required by
            # documentation. see http://docs.couchdb.org/en/latest/api/
            $value = $self->json->encode($value);
        }

        $value = uri_escape($value);
        $path .= $key . '=' . $value . '&';
    }

    # remove last '&'
    chop($path);

    return $path;
}

sub _make_path {
    my ($self, $data, $compat) = @_;

    my ($design, $view, $show, $list);

    if (exists $data->{view}) {
        $data->{view} =~ s/^\///;
        ($design, $view) = split(/\//, $data->{view}, 2);
    }

    if (exists $data->{show}) {
        $data->{show} =~ s/^\///;
        ($design, $show) = split(/\//, $data->{show}, 2);
    }

    $list = $data->{list} if exists $data->{list};

    my $path = $self->db . "/_design/${design}";
    if ($list) {
        $path .= "/_list/${list}/${view}";
    }
    elsif ($show) {
        $path .= "/_show/${show}";
        $path .= '/' . $data->{id} if defined $data->{id};
    }
    elsif ($view) {
        $path .= "/_view/${view}";
    }

    if (keys %{ $data->{opts} }) {
        my $params = $self->_uri_encode($data->{opts}, $compat);
        $path .= '?' . $params if $params;
    }

    return $path;
}

sub _build_uri {
    my ($self, $path) = @_;

    my $uri = $self->ssl ? 'https' : 'http';
    $uri .= '://' . $self->host . ':' . $self->port;
    $uri .= '/' . $path;
    $uri = URI->new($uri);
    $uri->userinfo($self->user . ':' . $self->pass)
        if ($self->user and $self->pass);

    return $uri;
}

sub _call {
    my ($self, $path, $accept_stale, $content, $ct) = @_;

    binmode(STDERR, ":encoding(UTF-8)") if $self->debug;

    # cleanup old error
    $self->clear_error if $self->has_error;

    my $uri = $self->_build_uri($path);

    $self->_log($self->method . ": $uri") if $self->debug;

    my $req = HTTP::Request->new();
    $req->method($self->method);
    $req->uri($uri);

    if ($content) {

        # make sure stringified keys and values return their original state
        # because otherwise JSON will encode numbers as strings for example
        my $c = eval dump $content;    ## no critic

        # ensure couchDB _id is a string as required
        # TODO: if support for _bulk_doc API is added we also need to make
        # sure every document ID is a string!
        if (ref $c eq 'HASH' && !defined $ct) {
            $c->{_id} .= '' if exists $c->{_id};
        }

        if ($self->debug) {
            $self->_log('Payload: ' . $self->_dump($content));
        }

        $req->content((
                  $ct
                ? $content
                : $self->json->encode($c)));
    }

    $self->agent->default_header('Content-Type' => $ct || "application/json");
    my $res = $self->agent->request($req);

    if ($self->method eq 'HEAD' and $res->header('ETag')) {
        $self->_log('Revision: ' . $res->header('ETag')) if $self->debug;
        return $res->header('ETag');
    }

    # retry with stale=update_after in case of a timeout
    if ($accept_stale and $res->status_line eq '500 read timeout') {
        $uri->query_param_append(stale => 'update_after');
        $req->uri($uri);
        $res = $self->agent->request($req);
    }

    # try JSON decoding response content all the time
    my $result;
    eval { $result = $self->json->decode($res->content) };
    unless ($@) {
        $self->_log('Result: ' . $self->_dump($result)) if $self->debug;
    }

    if ($res->is_success) {
        return $result if $result;

        if ($self->debug) {
            my $dc = $res->decoded_content;
            chomp $dc;
            $self->_log('Result: ' . $self->_dump($dc));
        }

        return {
            file         => $res->decoded_content,
            content_type => [ $res->content_type ]->[0],
        };
    }
    else {
        $self->error($res->status_line . ': ' . $res->content);
    }

    return;
}

sub _hash {
    my ($self, $head, $val, @tail) = @_;

    if ($#tail == 0) {
        return $head->{ shift(@tail) } = $val;
    }
    else {
        return $self->_hash($head->{ shift(@tail) } //= {}, $val, @tail);
    }
}

sub _dump {
    my ($self, $obj) = @_;

    my %options;
    if ($self->debug) {
        $options{colored} = 1;
    }
    else {
        $options{colored}   = 0;
        $options{multiline} = 0;
    }

    require Data::Printer;
    Data::Printer->import(%options) unless __PACKAGE__->can('np');

    my $dump;
    if (ref $obj) {
        $dump = np($obj, %options);
    }
    else {
        $dump = np(\$obj, %options);
    }

    return $dump;
}

sub _log {
    my ($self, $msg) = @_;

    print STDERR __PACKAGE__ . ': ' . $msg . $/;

    return;
}


1;    # End of Store::CouchDB

__END__

=pod

=encoding UTF-8

=head1 NAME

Store::CouchDB - Store::CouchDB - a simple CouchDB driver

=head1 VERSION

version 4.3

=head1 SYNOPSIS

Store::CouchDB is a very thin wrapper around CouchDB. It is essentially
a set of calls I use in production and is by no means a complete
library, it is just complete enough for the things I need to do.

Refer to the CouchDB Documentation at: L<http://docs.couchdb.org/en/latest/>

    use Store::CouchDB;

    my $sc = Store::CouchDB->new(host => 'localhost', db => 'your_db');
    # OR
    my $sc = Store::CouchDB->new();
    $sc->config({host => 'localhost', db => 'your_db'});
    my $array_ref = $db->get_array_view({
        view   => 'design_doc/view_name',
        opts   => { key => $key },
    });

=head1 ATTRIBUTES

=head2 debug

Sets the class in debug mode

Default: false

=head2 host

Default: localhost

=head2 port

Default: 5984

=head2 ssl

Connect to host using SSL/TLS.

Default: false

=head2 db / has_db

The database name to use.

=head2 user

The DB user to authenticate as. optional

=head2 pass

The password for the user to authenticate with. required if user is given.

=head2 method

This is internal and sets the request method to be used (GET|POST)

Default: GET

=head2 error / has_error

This is set if an error has occured and can be called to get the last
error with the 'has_error' predicate.

    $sc->has_error

Error string if there was an error

=head2 purge_limit

How many documents shall we try to purge.

Default: 5000

=head2 timeout

Timeout in seconds for each HTTP request. Passed onto LWP::UserAgent.
In case of a view or list related query where the view has not been updated in
a long time this will timeout and a new request with the C<stale> option set to
C<update_after> will be made to avoid blocking.
See http://docs.couchdb.org/en/latest/api/ddoc/views.html

Set this very high if you don't want stale results.

Default: 30

=head2 json

=head2 agent

=head1 METHODS

=head2 new

The Store::CouchDB class takes a any of the attributes described above as parameters.

=head2 get_doc

The get_doc call returns a document by its ID. If no document ID is given it
returns undef

    my $doc = $sc->get_doc({ id => 'doc_id', rev => '1-rev', dbname => 'database' });

where the dbname key is optional. Alternatively this works too:

    my $doc = $sc->get_doc('doc_id');

=head2 head_doc

If all you need is the revision a HEAD call is enough.

    my $rev = $sc->head_doc('doc_id');

=head2 all_docs

This call returns a list of document IDs with their latest revision by default.
Use C<include_docs> to get all Documents attached as well.

    my @docs = $sc->all_docs({ include_docs => 'true' });

=head2 get_design_docs

The get_design_docs call returns all design document names in an array.
You can add C<include_docs => 'true'> to get whole design documents.

    my @docs = $sc->get_design_docs({ dbname => 'database' });

Again the C<dbname> key is optional.

=head2 put_doc

The put_doc call writes a document to the database and either updates a
existing document if the _id field is present or writes a new one.
Updates can also be done with the C<update_doc> call if you want to prevent
creation of a new document in case the document ID is missing in your input
hashref.

    my ($id, $rev) = $sc->put_doc({ doc => { .. }, dbname => 'database' });

=head2 del_doc

The del_doc call marks a document as deleted. CouchDB needs a revision
to delete a document which is good for security but is not practical for
me in some situations. If no revision is supplied del_doc will get the
document, find the latest revision and delete the document. Returns the
revision in SCALAR context, document ID and revision in ARRAY context.

    my $rev = $sc->del_doc({ id => 'doc_id', rev => 'r-evision', dbname => 'database' });

=head2 update_doc

B<WARNING: as of Version C<3.4> this method breaks old code!>

The use of C<update_doc()> was discouraged before this version and was merely a
wrapper for put_doc, which became unnecessary. Please make sure you update your
code if you were using this method before version C<3.4>.

C<update_doc> refuses to push a document if the document ID is missing or the
document does not exist. This will make sure that you can only update existing
documents and not accidentally create a new one.

            $id = $sc->update_doc({ doc => { _id => '', _rev => '', ... } });
    ($id, $rev) = $sc->update_doc({ doc => { .. }, dbname => 'database' });

=head2 copy_doc

The copy_doc is _not_ the same as the CouchDB equivalent. In CouchDB the
copy command wants to have a name/id for the new document which is
mandatory and can not be ommitted. I find that inconvenient and made
this small wrapper. All it does is getting the doc to copy, removes the
_id and _rev fields and saves it back as a new document.

    my ($id, $rev) = $sc->copy_doc({ id => 'doc_id', dbname => 'database' });

=head2 show_doc

call a show function on a document to transform it.

    my $content = $sc->show_doc({ show => 'design_doc/show_name' });

=head2 get_view

There are several ways to represent the result of a view and various
ways to query for a view. All the views support parameters but there are
different functions for GET/POST view handling and representing the
reults.
The get_view uses GET to call the view and returns a hash with the _id
as the key and the document as a value in the hash structure. This is
handy for getting a hash structure for several documents in the DB.

    my $hashref = $sc->get_view({
        view => 'design_doc/view_name',
        opts => { key => $key },
    });

=head2 get_post_view

The get_post_view uses POST to call the view and returns a hash with the _id
as the key and the document as a value in the hash structure. This is
handy for getting a hash structure for several documents in the DB.

    my $hashref = $sc->get_post_view({
        view => 'design_doc/view_name',
        opts => [ $key1, $key2, $key3, ... ],
    });

=head2 get_view_array

The get_view_array uses GET to call the view and returns an array
of matched documents. This view functions is the one I use
most and has the best support for corner cases.

    my @docs = @{ $sc->get_array_view({
        view => 'design_doc/view_name',
        opts => { key => $key },
    }) };

A normal response hash would be the "value" part of the document with
the _id moved in as "id". If the response is not a HASH (the request was
resulting in key/value pairs) the entire doc is returned resulting in a
hash of key/value/id per document.

=head2 get_array_view

Same as get_view_array only returns a real array. Use either one
depending on your use case and convenience.

=head2 list_view

use the _list function on a view to transform its output. if your view contains
a reduce function you have to add

    opts => { reduce => 'false' }

to your hash.

    my $content = $sc->list_view({
        list => 'list_name',
        view => 'design/view',
    #   opts => { reduce => 'false' },
    });

=head2 changes

First draft of a changes feed implementation. Currently just returns the whole
JSON structure received. This might change in the future. As usual the C<dbname>
key is optional if the database name is already set via the C<db> attribute.

    my $changes = $sc->changes({dbname => 'database', limit => 100, since => 'now' });

=head2 purge

This function tries to find deleted documents via the _changes call and
then purges as many deleted documents as defined in $self->purge_limit
which currently defaults to 5000. This call is somewhat experimental in
the moment.

    my $result = $sc->purge({ dbname => 'database' });

=head2 compact

This compacts the DB file and optionally calls purge and cleans up the
view index as well.

    my $result = $sc->compact({ purge => 1, view_compact => 1 });

=head2 put_file

To add an attachement to CouchDB use the put_file method. 'file' because
it is shorter than attachement and less prone to misspellings. The
put_file method works like the put_doc function and will add an
attachement to an existing doc if the '_id' parameter is given or creates
a new empty doc with the attachement otherwise.
The 'file' and 'filename' parameters are mandatory.

    my ($id, $rev) = $sc->put_file({ file => 'content', filename => 'file.txt', id => 'doc_id' });

=head2 get_file

Get a file attachement from a CouchDB document.

    my $content = $sc->get_file({ id => 'doc_id', filename => 'file.txt' });

=head2 del_file

Delete a file attachement from a CouchDB document.

    my $content = $sc->del_file({ id => 'doc_id', rev => 'r-evision', filename => 'file.txt' });

=head2 config

This can be called with a hash of config values to configure the databse
object. I use it frequently with sections of config files.

    $sc->config({ host => 'HOST', port => 'PORT', db => 'DATABASE' });

=head2 create_db

Create a Database

    my $result = $sc->create_db('name');

=head2 delete_db

Delete/Drop a Databse

    my $result = $sc->delete_db('name');

=head2 all_dbs

Get a list of all Databases

    my @db = $sc->all_dbs;

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/norbu09/Store-CouchDB/issues>.
Pull requests welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Store::CouchDB

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/norbu09/Store-CouchDB>

=item * MetaCPAN

L<https://metacpan.org/module/Store::CouchDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Store::CouchDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Store::CouchDB>

=back

=head1 ACKNOWLEDGEMENTS

Thanks for DB::CouchDB which was very enspiring for writing this library

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
