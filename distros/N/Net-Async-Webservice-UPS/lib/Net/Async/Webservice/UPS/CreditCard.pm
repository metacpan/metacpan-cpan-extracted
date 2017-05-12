package Net::Async::Webservice::UPS::CreditCard;
$Net::Async::Webservice::UPS::CreditCard::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::CreditCard::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str Int);
use Net::Async::Webservice::UPS::Types ':types';
use namespace::autoclean;

# ABSTRACT: a credit card to pay UPS shipments with


has code => (
    is => 'ro',
    isa => CreditCardCode,
    required => 1,
);


has type => (
    is => 'ro',
    isa => CreditCardType,
    required => 1,
);


has number => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has expiration_year => (
    is => 'ro',
    isa => Int,
    required => 1,
);


has expiration_month => (
    is => 'ro',
    isa => Int,
    required => 1,
);


has security_code => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has address => (
    is => 'ro',
    isa => Address,
    required => 1,
);

my %code_for_type = (
    AMEX => '01',
    Discover => '03',
    MasterCard => '04',
    Optima => '05',
    VISA => '06',
    Bravo => '07',
    Diners => '08',
);
my %type_for_code = reverse %code_for_type;


sub type_for_code {
    my ($code) = @_;
    return $type_for_code{$code};
}


around BUILDARGS => sub {
    my ($orig,$class,@etc) = @_;
    my $args = $class->$orig(@etc);
    if ($args->{code} and not $args->{type}) {
        $args->{type} = $type_for_code{$args->{code}};
        if (!defined $args->{type}) {
            require Carp;
            Carp::croak "Bad credit card code $args->{code}";
        }
    }
    elsif ($args->{type} and not $args->{code}) {
        $args->{code} = $code_for_type{$args->{type}};
        if (!defined $args->{code}) {
            require Carp;
            Carp::croak "Bad credit card type $args->{type}";
        }
    }
    return $args;
};


sub as_hash {
    my ($self) = @_;

    return {
        Type => $self->code,
        Number => $self->number,
        ExpirationDate => sprintf('%02d%02d',$self->expiration_month,$self->expiration_year),
        ( $self->security_code ? ( SecurityCode => $self->security_code ) : () ),
        %{$self->address->as_hash('Ship')},
    };
}


sub cache_id { return $_[0]->number }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::CreditCard - a credit card to pay UPS shipments with

=head1 VERSION

version 1.1.4

=head1 ATTRIBUTES

=head2 C<code>

Enum, L<Net::Async::Webservice::UPS::Types/CreditCardCode>, one of
C<01> C<03> C<04> C<05> C<06> C<07> C<08>. If not specified, it will
be derived from the L</type>.

=head2 C<type>

Enum, L<Net::Async::Webservice::UPS::Types/CreditCardType>, one of
C<AMEX> C<Discover> C<MasterCard> C<Optima> C<VISA> C<Bravo>
C<Diners>. If not specified, it will be derived from the L</code>.

=head2 C<number>

Required string, the card number.

=head2 C<expiration_year>

Required integer, the year of expiration.

=head2 C<expiration_month>

Required integer, the month of expiration.

=head2 C<security_code>

Optional string, the card's security code (CVV2 or equivalent).

=head2 C<address>

Required, instance of L<Net::Async::Webservice::UPS::Address>, the
billing address associated with the credit card.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS requests to represent this
credit card.

=head2 C<cache_id>

Returns a string identifying this card.

=head1 FUNCTIONS

=head2 C<type_for_code>

  my $code = Net::Async::Webservice::UPS::CreditCard::type_for_code(2);

Function that returns the credit card type name given the code number.

=for Pod::Coverage BUILDARGS

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
