package Net::Blossom::Server::Request;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(method path body remote_addr content_length content_type _headers _query);
use Scalar::Util qw(blessed);

my $TOKEN = qr/[!#$%&'*+\-.^_`|~0-9A-Za-z]+/;

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(method path query headers body remote_addr content_length content_type);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    _validate_required_scalar(\%args, 'method');
    croak "method must be an HTTP token" unless $args{method} =~ /\A$TOKEN\z/;
    $args{method} = uc $args{method};

    _validate_required_scalar(\%args, 'path');
    croak "path must start with /" unless $args{path} =~ m{\A/};
    croak "path must not contain a query string" if $args{path} =~ /\?/;

    $args{headers} = {} unless defined $args{headers};
    my $headers = _normalize_headers($args{headers});

    $args{query} = {} unless defined $args{query};
    my $query = _normalize_query($args{query});

    if (!defined $args{content_type}) {
        $args{content_type} = $headers->{'content-type'}{value}
            if exists $headers->{'content-type'};
    }
    elsif (ref($args{content_type})) {
        croak "content_type must be a scalar";
    }

    if (!defined $args{content_length}) {
        $args{content_length} = $headers->{'content-length'}{value}
            if exists $headers->{'content-length'};
    }
    _validate_content_length($args{content_length}) if defined $args{content_length};

    croak "remote_addr must be a scalar" if defined $args{remote_addr} && ref($args{remote_addr});
    _validate_body($args{body}) if defined $args{body};

    $args{_headers} = $headers;
    $args{_query} = $query;
    delete @args{qw(headers query)};
    return bless \%args, $class;
}

sub headers {
    my ($self) = @_;
    return { map { $self->_headers->{$_}{name} => $self->_headers->{$_}{value} } keys %{$self->_headers} };
}

sub header {
    my ($self, $name) = @_;
    return undef unless defined $name;
    my $header = $self->_headers->{lc $name};
    return defined $header ? $header->{value} : undef;
}

sub query {
    my ($self) = @_;
    my %query;
    for my $name (keys %{$self->_query}) {
        my $value = $self->_query->{$name};
        $query{$name} = ref($value) eq 'ARRAY' ? [@$value] : $value;
    }
    return \%query;
}

sub query_param {
    my ($self, $name) = @_;
    return undef unless defined $name && exists $self->_query->{$name};
    my $value = $self->_query->{$name};
    return ref($value) eq 'ARRAY' ? $value->[0] : $value;
}

sub query_params {
    my ($self, $name) = @_;
    return () unless defined $name && exists $self->_query->{$name};
    my $value = $self->_query->{$name};
    return ref($value) eq 'ARRAY' ? @$value : ($value);
}

sub has_body {
    my ($self) = @_;
    return 1 if defined $self->body && ref($self->body);
    return 1 if defined $self->body && length $self->body;
    return 1 if defined $self->content_length && $self->content_length > 0;
    return 0;
}

sub _validate_required_scalar {
    my ($args, $field) = @_;
    croak "$field is required" unless exists $args->{$field} && defined $args->{$field};
    croak "$field must be a scalar" if ref($args->{$field});
    croak "$field is required" unless length $args->{$field};
}

sub _normalize_headers {
    my ($headers) = @_;
    croak "headers must be a hash reference" unless ref($headers) eq 'HASH';

    my %normalized;
    for my $name (keys %$headers) {
        croak "header names must be HTTP tokens"
            unless defined $name && !ref($name) && $name =~ /\A$TOKEN\z/;
        croak "header values must be defined" unless defined $headers->{$name};
        croak "header values must be scalars" if ref($headers->{$name});

        my $lower = lc $name;
        croak "duplicate header: $name" if exists $normalized{$lower};
        $normalized{$lower} = {
            name  => $name,
            value => $headers->{$name},
        };
    }

    return \%normalized;
}

sub _normalize_query {
    my ($query) = @_;
    croak "query must be a hash reference" unless ref($query) eq 'HASH';

    my %normalized;
    for my $name (keys %$query) {
        croak "query parameter names must be defined" unless defined $name;
        my $value = $query->{$name};
        if (ref($value) eq 'ARRAY') {
            for my $item (@$value) {
                croak "query values must be defined" unless defined $item;
                croak "query values must be scalars" if ref($item);
            }
            $normalized{$name} = [@$value];
        }
        else {
            croak "query values must be defined" unless defined $value;
            croak "query values must be scalars" if ref($value);
            $normalized{$name} = $value;
        }
    }

    return \%normalized;
}

sub _validate_content_length {
    my ($content_length) = @_;
    croak "content_length must be a scalar" if ref($content_length);
    croak "content_length must be a non-negative integer"
        unless $content_length =~ /\A\d+\z/;
}

sub _validate_body {
    my ($body) = @_;
    return unless ref($body);
    return if blessed($body) && ($body->can('read') || $body->can('getline'));
    croak "body must be a scalar or stream object";
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Request - Framework-neutral Blossom server request

=head1 SYNOPSIS

    use Net::Blossom::Server::Request;

    my $request = Net::Blossom::Server::Request->new(
        method  => 'PUT',
        path    => '/upload',
        headers => {
            'Content-Type'   => 'image/png',
            'Content-Length' => 1024,
        },
        body    => $stream,
    );

    my $type = $request->content_type;

=head1 DESCRIPTION

C<Net::Blossom::Server::Request> is the normalized request object used by
C<Net::Blossom::Server>. It is intentionally independent of PSGI, PAGI, Plack,
and any daemon framework.

Adapters should translate their native request representation into this object
before calling the Blossom server core.

=head1 CONSTRUCTOR

=head2 new

    my $request = Net::Blossom::Server::Request->new(%args);

Required arguments:

=over 4

=item * C<method>

HTTP method. It must be an HTTP token and is normalized to uppercase.

=item * C<path>

Request path. It must start with C</> and must not contain a query string.

=back

Optional arguments:

=over 4

=item * C<headers>

Hash reference of HTTP request headers. Header names are case-insensitive and
duplicate case-insensitive names croak.

=item * C<query>

Hash reference of query parameters. Values may be scalars or array references of
scalars.

=item * C<body>

Request body. It may be a scalar byte string or a stream object that provides
C<read> or C<getline>.

=item * C<remote_addr>

Client address as provided by the adapter.

=item * C<content_length>

Content length. Defaults from the C<Content-Length> header when present. It must
be a non-negative integer.

=item * C<content_type>

Content type. Defaults from the C<Content-Type> header when present.

=back

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 method

Returns the uppercase HTTP method.

=head2 path

Returns the request path.

=head2 body

Returns the scalar body or stream object.

=head2 remote_addr

Returns the adapter-provided client address.

=head2 content_length

Returns the content length, when known.

=head2 content_type

Returns the content type, when known.

=head1 METHODS

=head2 headers

    my $headers = $request->headers;

Returns a copy hash reference of request headers.

=head2 header

    my $value = $request->header($name);

Returns a header value using case-insensitive lookup. Returns C<undef> when the
header is absent.

=head2 query

    my $query = $request->query;

Returns a copy hash reference of query parameters. Repeated values are returned
as copied array references.

=head2 query_param

    my $value = $request->query_param($name);

Returns the first query value for C<$name>, or C<undef> when absent.

=head2 query_params

    my @values = $request->query_params($name);

Returns all query values for C<$name>.

=head2 has_body

    my $has_body = $request->has_body;

Returns true when the request has a scalar body, a stream body, or a positive
C<content_length>.

=cut
