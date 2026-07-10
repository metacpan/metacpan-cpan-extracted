package Net::Blossom::Server::Error;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::Server::Response;

use Carp qw(croak);
use Class::Tiny qw(status reason _headers);

my $TOKEN = qr/[!#$%&'*+\-.^_`|~0-9A-Za-z]+/;

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(status reason headers);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "status is required" unless exists $args{status} && defined $args{status};
    croak "status must be an HTTP status code"
        unless !ref($args{status}) && $args{status} =~ /\A[1-5][0-9][0-9]\z/;

    $args{reason} = '' unless defined $args{reason};
    croak "reason must be a scalar" if ref($args{reason});
    croak "reason must not contain CR or LF" if $args{reason} =~ /[\r\n]/;

    $args{headers} = {} unless defined $args{headers};
    $args{_headers} = _normalize_headers($args{headers});
    delete $args{headers};

    return bless \%args, $class;
}

sub throw {
    my $class = shift;
    die $class->new(@_);
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

sub as_response {
    my ($self) = @_;
    return Net::Blossom::Server::Response->error(
        $self->status,
        $self->reason,
        headers => $self->headers,
    );
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

1;

=pod

=head1 NAME

Net::Blossom::Server::Error - Typed Blossom server error

=head1 SYNOPSIS

    use Net::Blossom::Server::Error;

    Net::Blossom::Server::Error->throw(
        status  => 401,
        reason  => 'Unauthorized',
        headers => { 'WWW-Authenticate' => 'Nostr' },
    );

=head1 DESCRIPTION

C<Net::Blossom::Server::Error> represents an expected server-side failure that
gateway adapters can turn into an HTTP response. It is used for authorization
failures and other controlled errors where the status code is part of the API.

=head1 CONSTRUCTOR

=head2 new

    my $error = Net::Blossom::Server::Error->new(%args);

Required C<status> must be an HTTP status code from C<100> through C<599>.

Optional C<reason> defaults to the empty string and must not contain CR or LF.
Optional C<headers> defaults to an empty hash reference. Header values must be
defined scalars and must not contain CR or LF.

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 status

Returns the HTTP status code.

=head2 reason

Returns the reason string.

=head1 METHODS

=head2 throw

    Net::Blossom::Server::Error->throw(%args);

Constructs and dies with a typed error object.

=head2 headers

    my $headers = $error->headers;

Returns a copy hash reference of response headers.

=head2 header

    my $value = $error->header($name);

Returns a header value using case-insensitive lookup.

=head2 as_response

    my $response = $error->as_response;

Returns a C<Net::Blossom::Server::Response> for the error.

=cut
