##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/BankAccount.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/customer_bank_accounts/object
package Net::API::Stripe::Payment::BankAccount;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Connect::ExternalAccount::Bank );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::BankAccount - A Stripe Payment Bank Account Object.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

These bank accounts are payment methods on Customer objects.

On the other hand External Accounts (L<Net::API::Stripe::Connect::Account::ExternalAccounts> / L<https://stripe.com/docs/api#external_accounts>) are transfer destinations on Account objects for Custom accounts (L<https://stripe.com/docs/connect/custom-accounts>). They can be bank accounts or debit cards as well, and are documented in the links above.

That being said, all the methods are exactly the same as L<Net::API::Stripe::Connect::ExternalAccount::Bank> so this module inherits 100% from it.

The only reason why I am keeping it here, ie because Stripe makes a distinction as mentioned above.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customer_bank_accounts>, L<https://stripe.com/docs/payments/ach-bank-transfers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
