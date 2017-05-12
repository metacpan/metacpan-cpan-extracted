package Store::CouchDB;

use Any::Moose;

# ABSTRACT: Store::CouchDB - a simple CouchDB driver

our $VERSION = '3.8'; # VERSION

use JSON;
use LWP::UserAgent;
use URI::Escape;
use Carp;
use Data::Dump 'dump';
use Types::Serialiser;


has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 },
    lazy    => 1,
);


has 'host' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => sub { 'localhost' },
);


has 'port' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
    default  => sub { 5984 },
);


has 'ssl' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 },
    lazy    => 1,
);


has 'db' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_db',
);


has 'user' => (
    is  => 'rw',
    isa => 'Str',
);


has 'pass' => (
    is  => 'rw',
    isa => 'Str',
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
    default => sub { 5000 },
);


has 'timeout' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 30 },
);


has 'json' => (
    is      => 'rw',
    isa     => 'JSON',
    default => sub {
        JSON->new->utf8->allow_nonref->allow_blessed->convert_blessed;
    },
);


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

    return unless $res->{rows}->[0];
    return $res->{rows};
}


sub get_design_docs {
    my ($self, $data) = @_;

    $self->_check_db($data);

    my $path = $self->db
        . '/_all_docs?descending=true&startkey="_design0"&endkey="_design"';
    my $params = $self->_uri_encode($data);
    $path .= $params if $params;

    $self->method('GET');
    my $res = $self->_call($path);

    return unless $res->{rows}->[0];
    return $res->{rows}
        if (ref $data eq 'HASH' and $data->{include_docs});

    my @design;
    foreach my $design (@{ $res->{rows} }) {
        my (undef, $name) = split(/\//, $design->{key}, 2);
        push(@design, $name);
    }

    return \@design;
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
    my $res = $self->_call($path, $data->{doc});

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

    if ($data->{name}) {
        $data->{doc}->{_id} = $data->{name};
    }

    unless (exists $data->{doc}->{_id} and defined $data->{doc}->{_id}) {
        carp "Document ID not defined";
        return;
    }

    $self->_check_db($data);

    my $rev = $self->head_doc($data->{doc}->{_id});
    unless ($rev) {
        carp "Document does not exist";
        return;
    }

    # store revision in original doc to be able to put_doc
    $data->{doc}->{_rev} = $rev;

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
    my $res = $self->_call($path);

    # fallback lookup for broken data consistency due to the way earlier
    # versions of this module where handling (or not) input data that had been
    # stringified by dumpers or otherwise internally
    # e.g. numbers were stored as strings which will be used as keys eventually
    unless ($res->{rows}->[0]) {
        $path = $self->_make_path($data, 1);
        $res = $self->_call($path);
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
    my $res = $self->_call($path, $opts);

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

    $self->_check_db($data);

    my $path = $self->_make_path($data);
    $self->method('GET');
    my $res = $self->_call($path);

    # fallback lookup for broken data consistency due to the way earlier
    # versions of this module where handling (or not) input data that had been
    # stringified by dumpers or otherwise internally
    # e.g. numbers were stored as strings which will be used as keys eventually
    unless ($res->{rows}->[0]) {
        $path = $self->_make_path($data, 1);
        $res = $self->_call($path);
    }

    my @result;
    foreach my $doc (@{ $res->{rows} }) {
        if ($doc->{doc}) {
            push(@result, $doc->{doc});
        }
        else {
            next unless exists $doc->{value};
            if (ref($doc->{value}) eq 'HASH') {
                $doc->{value}->{id} = $doc->{id};
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

    unless ($data->{view}) {
        carp "View not defined";
        return;
    }

    $self->_check_db($data);

    my $path = $self->_make_path($data);
    $self->method('GET');
    my $res = $self->_call($path);

    # fallback lookup for broken data consistency due to the way earlier
    # versions of this module where handling (or not) input data that had been
    # stringified by dumpers or otherwise internally
    # e.g. numbers were stored as strings which will be used as keys eventually
    unless ($res->{rows}->[0]) {
        $path = $self->_make_path($data, 1);
        $res = $self->_call($path);
    }

    my $result;
    foreach my $doc (@{ $res->{rows} }) {
        if ($doc->{doc}) {
            push(@{$result}, $doc->{doc});
        }
        else {
            next unless exists $doc->{value};
            if (ref($doc->{value}) eq 'HASH') {
                $doc->{value}->{id} = $doc->{id};
                push(@{$result}, $doc->{value});
            }
            else {
                push(@{$result}, $doc);
            }
        }
    }

    return $result;
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

    return $self->_call($path);
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
        $resp->{ $_del->{seq} } = $self->_call($self->db . '/_purge', $opts);
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
        my $design = $self->get_design_docs();
        $self->method('POST');
        foreach my $doc (@{$design}) {
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
    my $res = $self->_call($path, $data->{file}, $data->{content_type});

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

        if ($key =~ m/key/) {

            # backwards compatibility with key, startkey, endkey as strings
            $value .= '' if ($compat && !ref($value));
        }
        else {
            unless (ref $value) {

                # copy $value to prevent stringifying
                my $cvalue = $value;

                # respect JSON booleans
                $value = Types::Serialiser::true  if $cvalue eq 'true';
                $value = Types::Serialiser::false if $cvalue eq 'false';
            }
        }

        $value = uri_escape($self->json->encode($value));
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

sub _call {
    my ($self, $path, $content, $ct) = @_;

    binmode(STDERR, ":encoding(UTF-8)") if $self->debug;

    # cleanup old error
    $self->clear_error if $self->has_error;

    my $uri = ($self->ssl) ? 'https://' : 'http://';
    $uri .= $self->user . ':' . $self->pass . '@'
        if ($self->user and $self->pass);
    $uri .= $self->host . ':' . $self->port . '/' . $path;

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

    my $ua = LWP::UserAgent->new(timeout => $self->timeout);

    $ua->default_header('Content-Type' => $ct || "application/json");
    my $res = $ua->request($req);

    if ($self->method eq 'HEAD' and $res->header('ETag')) {
        $self->_log('Revision: ' . $res->header('ETag')) if $self->debug;
        return $res->header('ETag');
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
    Data::Printer->import(%options) unless __PACKAGE__->can('p');

    my $dump;
    if (ref $obj) {
        $dump = p($obj, %options);
    }
    else {
        $dump = p(\$obj, %options);
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

version 3.8

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

=head2 db

The databae name to use.

=head2 user

The DB user to authenticate as. optional

=head2 pass

The password for the user to authenticate with. required if user is given.

=head2 method

This is internal and sets the request method to be used (GET|POST)

Default: GET

=head2 error

This is set if an error has occured and can be called to get the last
error with the 'has_error' predicate.

    $sc->has_error

Error string if there was an error

=head2 purge_limit

How many documents shall we try to purge.

Default: 5000

=head2 timeout

Timeout in seconds for each HTTP request. Passed onto LWP::UserAgent

Default: 30

=head2 json

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

This call returns a list of document IDs and revisions by default.
Use C<include_docs> to get all Documents attached as well.

    my @docs = @{ $sc->all_docs({ include_docs => 'true' }) };

=head2 get_design_docs

The get_design_docs call returns all design document names in an array
reference. You can add C<include_docs => 'true'> to get the whole design document.

    my @docs = @{ $sc->get_design_docs({ dbname => 'database' }) };

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

            $id = $sc->update_doc({ doc => { _id => '', ... } });
    ($id, $rev) = $sc->update_doc({ doc => { .. }, name => 'doc_id', dbname => 'database' });

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

Same as get_array_view only returns a real array. Use either one
depending on your use case and convenience.

=head2 get_array_view

The get_array_view uses GET to call the view and returns an array
reference of matched documents. This view functions is the one I use
most and has the best support for corner cases.

    my @docs = @{ $sc->get_array_view({
        view => 'design_doc/view_name',
        opts => { key => $key },
    }) };

A normal response hash would be the "value" part of the document with
the _id moved in as "id". If the response is not a HASH (the request was
resulting in key/value pairs) the entire doc is returned resulting in a
hash of key/value/id per document.

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
