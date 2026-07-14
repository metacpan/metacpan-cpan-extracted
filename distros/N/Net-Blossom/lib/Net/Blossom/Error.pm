package Net::Blossom::Error;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(method url status reason x_reason), {
    headers => sub { {} },
    body    => '',
};
use overload '""' => 'as_string', fallback => 1;

sub BUILDARGS {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(method url status reason x_reason headers body);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    return \%args;
}

sub BUILD {
    my ($self) = @_;
    $self->headers({}) unless defined $self->headers;
    $self->body('') unless defined $self->body;
    _validate_required_scalar($self, $_) for qw(method url status reason);
    _validate_status($self->status);
    croak "headers must be a hash reference" unless ref($self->headers) eq 'HASH';
    croak "body must be a scalar" if ref($self->body);
    croak "x_reason must be a scalar" if defined $self->x_reason && ref($self->x_reason);
    return;
}

sub as_string {
    my ($self) = @_;
    my $message = $self->status . ' ' . ($self->reason || 'HTTP error');
    $message .= ': ' . $self->x_reason if defined $self->x_reason && length $self->x_reason;
    $message .= ' at ' . $self->method . ' ' . $self->url
        if defined $self->method && defined $self->url;
    return $message;
}

sub _validate_required_scalar {
    my ($self, $field) = @_;
    croak "$field is required" unless defined $self->$field;
    croak "$field must be a scalar" if ref($self->$field);
    croak "$field is required" if $field =~ /\A(?:method|url)\z/ && !length $self->$field;
}

sub _validate_status {
    my ($status) = @_;
    croak "status must be an HTTP status code"
        unless $status =~ /\A[1-5][0-9][0-9]\z/;
}

1;

=pod

=head1 NAME

Net::Blossom::Error - Blossom HTTP error object

=head1 SYNOPSIS

    my $error = eval { $client->get_blob($sha256); 1 } ? undef : $@;

    if (ref($error) && $error->isa('Net::Blossom::Error')) {
        warn $error->status;
        warn "$error";
    }

=head1 DESCRIPTION

C<Net::Blossom::Error> represents a non-success HTTP response from a Blossom
server. C<Net::Blossom::Client> dies with this object for non-402 HTTP failures.

The object stringifies to a compact diagnostic containing status, reason,
optional C<X-Reason>, method, and URL.

=head1 CONSTRUCTOR

=head2 new

    my $error = Net::Blossom::Error->new(%args);

Required arguments are C<method>, C<url>, C<status>, and C<reason>. C<status>
must be a three-digit HTTP status code from C<100> through C<599>.

Optional C<x_reason> is the server's C<X-Reason> diagnostic. Optional C<headers>
defaults to an empty hash reference. Optional C<body> defaults to the empty
string.

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 method

Returns the HTTP method.

=head2 url

Returns the request URL.

=head2 status

Returns the HTTP status code.

=head2 reason

Returns the HTTP reason phrase.

=head2 x_reason

Returns the optional C<X-Reason> diagnostic.

=head2 headers

Returns the response headers hash reference.

=head2 body

Returns the response body.

=head1 METHODS

=head2 as_string

    my $message = $error->as_string;

Returns the same diagnostic used by stringification.

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=head2 BUILD

Validates the constructed object for Class::Tiny.

=cut
