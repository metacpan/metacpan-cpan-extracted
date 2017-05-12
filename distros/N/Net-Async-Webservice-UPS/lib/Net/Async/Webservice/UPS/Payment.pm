package Net::Async::Webservice::UPS::Payment;
$Net::Async::Webservice::UPS::Payment::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Payment::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str Bool Enum);
use Net::Async::Webservice::UPS::Types ':types';
use namespace::autoclean;

# ABSTRACT: a payment method for UPS shipments


has method => (
    is => 'ro',
    isa => Enum[qw(prepaid third_party freight_collect)],
    default => 'prepaid',
);


has account_number => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has credit_card => (
    is => 'ro',
    isa => CreditCard,
    required => 0,
);


has address => (
    is => 'ro',
    isa => Address,
    required => 0,
);


around BUILDARGS => sub {
    my ($orig,$class,@etc) = @_;
    my $args = $class->$orig(@etc);

    if ($args->{method} eq 'prepaid') {
        if (not ($args->{credit_card} or $args->{account_number})) {
            require Carp;
            Carp::croak "account_number or credit_card required when payment method is 'prepaid'";
        }
    }
    elsif ($args->{method} eq 'third_party') {
        if (not ($args->{account_number} and $args->{address})) {
            require Carp;
            Carp::croak "account_number and address required when payment method is 'third_party'";
        }
    }
    elsif ($args->{method} eq 'freight_collect') {
        if (not ($args->{account_number} and $args->{address})) {
            require Carp;
            Carp::croak "account_number required when payment method is 'freight_collect'";
        }
    }

    return $args;
};


sub as_hash {
    my ($self) = @_;

    return {
        ($self->method eq 'prepaid') ? ( Prepaid => {
            BillShipper => {
                ( $self->account_number ? ( AccountNumber => $self->account_number ) :
                ( $self->credit_card ? ( CreditCard => $self->credit_card->as_hash ) :
                () ) ),
            },
        } ) :
        ($self->method eq 'third_party') ? ( BillThirdParty => {
            BillThirdPartyShipper => {
                AccountNumber => $self->account_number,
                ThirdPartyShipper => $self->address->as_hash('Ship'),
            },
        } ) :
        ($self->method eq 'freight_collect') ? ( FreightCollect => {
            BillReceiver => {
                AccountNumber => $self->account_number,
                %{$self->address->as_hash('Ship')},
            },
        } ) : ()
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Payment - a payment method for UPS shipments

=head1 VERSION

version 1.1.4

=head1 ATTRIBUTES

=head2 C<method>

Enum, one of C<prepaid> C<third_party> C<freight_collect>. Defaults to
C<prepaid>.

=head2 C<account_number>

A UPS account number to bill, required for C<third_party> and
C<freight_collect> payment methods. For C<prepaid>, either this or
L</credit_card> must be set.

=head2 C<credit_card>

A credit card (instance of L<Net::Async::Webservice::UPS::CreditCard>)
to bill.  For C<prepaid>, either this or L</account_number> must be
set.

=head2 C<address>

An address (instance of L<Net::Async::Webservice::UPS::Address>),
required for C<third_party> and C<freight_collect> payment methods.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS requests to represent this
payment method.

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
