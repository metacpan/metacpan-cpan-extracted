package Net::Blossom::Server::Response;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(status _headers), {
    body => '',
};
use JSON ();
use Scalar::Util qw(blessed);

my $TOKEN = qr/[!#$%&'*+\-.^_`|~0-9A-Za-z]+/;
my $JSON = JSON->new->utf8->canonical;

sub BUILDARGS {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(status headers body);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    $args{headers} = {} unless defined $args{headers};
    $args{_headers} = _normalize_headers($args{headers});
    delete $args{headers};

    return \%args;
}

sub BUILD {
    my ($self) = @_;
    croak "status is required" unless defined $self->status;
    _validate_status($self->status);
    $self->body('') unless defined $self->body;
    _validate_body($self->body);
    return;
}

sub json {
    my $class = shift;
    my ($data, %opts) = @_;
    _validate_options(\%opts, qw(status headers));
    my $body = $JSON->encode($data);
    return $class->new(
        status  => _status_option(\%opts, 200),
        headers => _headers_with_defaults(delete($opts{headers}), {
            'Content-Type'   => 'application/json',
            'Content-Length' => length($body),
        }),
        body    => $body,
    );
}

sub text {
    my $class = shift;
    my ($body, %opts) = @_;
    _validate_options(\%opts, qw(status headers));
    $body = '' unless defined $body;
    croak "text body must be a scalar" if ref($body);
    return $class->new(
        status  => _status_option(\%opts, 200),
        headers => _headers_with_defaults(delete($opts{headers}), {
            'Content-Type'   => 'text/plain; charset=utf-8',
            'Content-Length' => length($body),
        }),
        body    => $body,
    );
}

sub empty {
    my $class = shift;
    my ($status, %opts) = @_;
    _validate_options(\%opts, qw(headers));
    $status = 204 unless defined $status;
    return $class->new(
        status  => $status,
        headers => _headers_with_defaults(delete($opts{headers}), {
            'Content-Length' => 0,
        }),
        body    => '',
    );
}

sub redirect {
    my $class = shift;
    my ($location, %opts) = @_;
    _validate_options(\%opts, qw(status headers));
    croak "location is required" unless defined $location && !ref($location) && length $location;
    return $class->new(
        status  => _status_option(\%opts, 307),
        headers => _headers_with_defaults(delete($opts{headers}), {
            Location         => $location,
            'Content-Length' => 0,
        }),
        body    => '',
    );
}

sub error {
    my $class = shift;
    my ($status, $reason, %opts) = @_;
    _validate_options(\%opts, qw(headers));
    croak "reason must be a scalar" if defined $reason && ref($reason);
    my %defaults = ('Content-Length' => 0);
    $defaults{'X-Reason'} = $reason if defined $reason && length $reason;
    return $class->new(
        status  => $status,
        headers => _headers_with_defaults(delete($opts{headers}), \%defaults),
        body    => '',
    );
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

sub header_pairs {
    my ($self) = @_;
    my @pairs;
    for my $key (sort { $self->_headers->{$a}{name} cmp $self->_headers->{$b}{name} } keys %{$self->_headers}) {
        push @pairs, $self->_headers->{$key}{name}, $self->_headers->{$key}{value};
    }
    return \@pairs;
}

sub body_chunks {
    my ($self) = @_;
    return [@{$self->body}] if ref($self->body) eq 'ARRAY';
    croak "stream body cannot be returned as chunks" if ref($self->body);
    return [$self->body];
}

sub _validate_status {
    my ($status) = @_;
    croak "status must be a scalar" if ref($status);
    croak "status must be an HTTP status code"
        unless $status =~ /\A[1-5][0-9][0-9]\z/;
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
        croak "header values must not contain CR or LF"
            if $headers->{$name} =~ /[\r\n]/;

        my $lower = lc $name;
        croak "duplicate header: $name" if exists $normalized{$lower};
        $normalized{$lower} = {
            name  => $name,
            value => $headers->{$name},
        };
    }

    return \%normalized;
}

sub _validate_body {
    my ($body) = @_;
    return unless ref($body);

    if (ref($body) eq 'ARRAY') {
        for my $chunk (@$body) {
            croak "body array values must be defined" unless defined $chunk;
            croak "body array values must be scalars" if ref($chunk);
        }
        return;
    }

    return if blessed($body) && ($body->can('read') || $body->can('getline'));
    croak "body must be a scalar, array reference, or stream object";
}

sub _validate_options {
    my ($opts, @known) = @_;
    my %known = map { $_ => 1 } @known;
    my @unknown = grep { !exists $known{$_} } keys %$opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;
}

sub _headers_with_defaults {
    my ($headers, $defaults) = @_;
    $headers = {} unless defined $headers;
    croak "headers must be a hash reference" unless ref($headers) eq 'HASH';

    my %merged = %$headers;
    my %seen = map { lc($_) => 1 } keys %merged;
    for my $name (keys %$defaults) {
        next if $seen{lc $name};
        $merged{$name} = $defaults->{$name};
    }

    return \%merged;
}

sub _status_option {
    my ($opts, $default) = @_;
    my $status = delete $opts->{status};
    return defined $status ? $status : $default;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Response - Framework-neutral Blossom server response

=head1 SYNOPSIS

    use Net::Blossom::Server::Response;

    my $response = Net::Blossom::Server::Response->json(
        { ok => 1 },
        status => 201,
    );

    my $status = $response->status;

=head1 DESCRIPTION

C<Net::Blossom::Server::Response> represents a server response before any PSGI,
PAGI, or other gateway adapter turns it into gateway-native output.

Responses may carry scalar bodies, array reference bodies, or stream objects.
Gateway adapters are responsible for mapping those body forms to their native
output protocol.

=head1 CONSTRUCTORS

=head2 new

    my $response = Net::Blossom::Server::Response->new(%args);

Required C<status> must be an HTTP status code from C<100> through C<599>.

Optional C<headers> defaults to an empty hash reference. Header names are
case-insensitive and duplicate case-insensitive names croak. Header values must
be defined scalars and must not contain CR or LF.

Optional C<body> defaults to the empty string. It may be a scalar byte string, an
array reference of scalar byte strings, or a stream object that provides C<read>
or C<getline>.

=head2 json

    my $response = Net::Blossom::Server::Response->json($data, %opts);

Encodes C<$data> as canonical UTF-8 JSON. C<status> defaults to C<200>. The
response includes C<Content-Type: application/json> and C<Content-Length> unless
those headers are supplied in C<headers>.

=head2 text

    my $response = Net::Blossom::Server::Response->text($body, %opts);

Builds a text response. C<status> defaults to C<200>. The response includes
C<Content-Type: text/plain; charset=utf-8> and C<Content-Length> unless those
headers are supplied in C<headers>.

=head2 empty

    my $response = Net::Blossom::Server::Response->empty($status, %opts);

Builds an empty response. C<status> defaults to C<204>. The response includes
C<Content-Length: 0> unless supplied in C<headers>.

=head2 redirect

    my $response = Net::Blossom::Server::Response->redirect($location, %opts);

Builds a redirect response. C<status> defaults to C<307>. C<$location> is
required. The response includes C<Location> and C<Content-Length: 0>.

=head2 error

    my $response = Net::Blossom::Server::Response->error($status, $reason, %opts);

Builds an empty error response. C<$reason>, when defined and non-empty, is sent
as C<X-Reason> and therefore must not contain CR or LF.

=head1 ACCESSORS

=head2 status

Returns the HTTP status code.

=head2 body

Returns the scalar, array reference, or stream body.

=head1 METHODS

=head2 headers

    my $headers = $response->headers;

Returns a copy hash reference of response headers.

=head2 header

    my $value = $response->header($name);

Returns a header value using case-insensitive lookup. Returns C<undef> when the
header is absent.

=head2 header_pairs

    my $pairs = $response->header_pairs;

Returns an array reference suitable for PSGI-style C<< [name => value, ...] >>
headers.

=head2 body_chunks

    my $chunks = $response->body_chunks;

Returns scalar and array reference bodies as an array reference of chunks. Stream
bodies croak because they must be consumed by the gateway adapter.

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=head2 BUILD

Validates the constructed object for Class::Tiny.

=cut
