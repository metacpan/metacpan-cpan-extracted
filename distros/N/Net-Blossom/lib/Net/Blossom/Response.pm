package Net::Blossom::Response;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(method url status reason), {
    headers => sub { {} },
    content => '',
};

sub BUILDARGS {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(method url status reason headers content);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    return \%args;
}

sub BUILD {
    my ($self) = @_;
    $self->headers({}) unless defined $self->headers;
    $self->content('') unless defined $self->content;
    _validate_required_scalar($self, $_) for qw(method url status reason);
    _validate_status($self->status);
    croak "headers must be a hash reference" unless ref($self->headers) eq 'HASH';
    croak "content must be a scalar" if ref($self->content);
    return;
}

sub header {
    my ($self, $name) = @_;
    return undef unless defined $name;
    my $wanted = lc $name;
    for my $key (keys %{$self->headers}) {
        return $self->headers->{$key} if lc($key) eq $wanted;
    }
    return undef;
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

Net::Blossom::Response - Blossom HTTP success response object

=head1 SYNOPSIS

    my $response = $client->get_blob($sha256);

    say $response->status;
    say $response->header('content-type');

=head1 DESCRIPTION

C<Net::Blossom::Response> represents a successful HTTP response returned by
C<Net::Blossom::Client>.

=head1 CONSTRUCTOR

=head2 new

    my $response = Net::Blossom::Response->new(%args);

Required arguments are C<method>, C<url>, C<status>, and C<reason>. C<status>
must be a three-digit HTTP status code from C<100> through C<599>.

Optional C<headers> defaults to an empty hash reference. Optional C<content>
defaults to the empty string.

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

=head2 headers

Returns the response headers hash reference.

=head2 content

Returns the response body bytes as a scalar.

=head1 METHODS

=head2 header

    my $value = $response->header($name);

Returns a response header value using case-insensitive lookup. Returns C<undef>
when C<$name> is undefined or the header is absent.

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=head2 BUILD

Validates the constructed object for Class::Tiny.

=cut
