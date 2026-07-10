package Net::Blossom::PaymentRequired;

use strictures 2;

use parent 'Net::Blossom::Error';

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(method url status reason x_reason headers body payment_challenges);

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(method url status reason x_reason headers body payment_challenges);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    $args{headers} = {} unless defined $args{headers};
    $args{body} = '' unless defined $args{body};
    $args{payment_challenges} = {} unless defined $args{payment_challenges};
    croak "payment_challenges must be a hash reference"
        unless ref($args{payment_challenges}) eq 'HASH';

    my $payment_challenges = delete $args{payment_challenges};
    my $self = $class->SUPER::new(%args);
    croak "status must be 402 for PaymentRequired" unless $self->status == 402;
    $self->{payment_challenges} = $payment_challenges;
    return $self;
}

sub payment_methods {
    my ($self) = @_;
    return sort keys %{$self->payment_challenges};
}

sub payment_challenge {
    my ($self, $method) = @_;
    return undef unless defined $method;
    $method =~ s/\AX-//i;
    return $self->payment_challenges->{lc $method};
}

1;

=pod

=head1 NAME

Net::Blossom::PaymentRequired - Blossom 402 payment challenge error

=head1 SYNOPSIS

    my $error = eval { $client->get_blob($sha256); 1 } ? undef : $@;

    if (ref($error) && $error->isa('Net::Blossom::PaymentRequired')) {
        my @methods = $error->payment_methods;
        my $cashu   = $error->payment_challenge('cashu');
    }

=head1 DESCRIPTION

C<Net::Blossom::PaymentRequired> represents a C<402 Payment Required> response
from a Blossom server. It is a subclass of C<Net::Blossom::Error>.

When this object is produced by C<Net::Blossom::Client>, payment challenges are
parsed from non-reserved C<X-*> response headers. Known C<cashu> and
C<lightning> challenges are validated before being exposed. Unknown future
payment methods are preserved when they have a scalar non-empty payload.

=head1 CONSTRUCTOR

=head2 new

    my $error = Net::Blossom::PaymentRequired->new(%args);

Accepts the same required arguments as C<Net::Blossom::Error-E<gt>new>, but
C<status> must be C<402>. Optional C<payment_challenges> must be a hash reference
and defaults to an empty hash reference.

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

=head2 payment_challenges

Returns the payment challenge hash reference keyed by normalized method name.

=head1 METHODS

=head2 payment_methods

    my @methods = $error->payment_methods;

Returns sorted payment method names as a list.

=head2 payment_challenge

    my $challenge = $error->payment_challenge($method);

Returns the challenge string for C<$method>. C<$method> may include an C<X->
prefix. Returns C<undef> when the method is unknown or undefined.

=head2 as_string

Inherited from C<Net::Blossom::Error>.

=cut
