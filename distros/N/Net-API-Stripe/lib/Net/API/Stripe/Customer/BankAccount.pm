##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/BalanceTransaction.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/customer_bank_accounts
package Net::API::Stripe::Customer::BankAccount;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Connect::ExternalAccount::Bank );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::BankAccount - A Stripe Customer Bank Account Object

=head1 SYNOPSIS

    my $bt = $stripe->customer_bank_account({
        account_holder_name => 'Big Corp, Inc',
        account_holder_type => 'company',
        bank_name => 'Big Bank, Corp'
        country => 'us',
        currency => 'usd',
        customer => $customer_object,
        default_for_currency => $stripe->true,
        fingerprint => 'kshfkjhfkjsjdla',
        last4 => 1234,
        metadata => { transaction_id => 2222 },
        routing_number => 123,
        status => 'new',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This class represents a customer bank account. It is almost the same as the L<external account|Net::API::Stripe::Connect::ExternalAccount::Bank>, and it actually inherits all of its methods from it.

=head1 API SAMPLE

    {
      "id": "ba_1LI2gm2eZvKYlo2CwYyzfryc",
      "object": "bank_account",
      "account_holder_name": "Jane Austen",
      "account_holder_type": "company",
      "account_type": null,
      "bank_name": "STRIPE TEST BANK",
      "country": "US",
      "currency": "usd",
      "customer": null,
      "fingerprint": "1JWtPxqbdX5Gamtc",
      "last4": "6789",
      "metadata": {},
      "routing_number": "110000000",
      "status": "new"
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customer_bank_accounts>, L<https://stripe.com/docs/payments/bank-debits-transfers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
