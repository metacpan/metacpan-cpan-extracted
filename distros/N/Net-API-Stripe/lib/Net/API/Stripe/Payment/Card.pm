##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Card.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/cards/object
package Net::API::Stripe::Payment::Card;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Connect::ExternalAccount::Card );
    our( $VERSION ) = '0.1';
};

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Card - A Stripe Payment Card Object

=head1 VERSION

    0.1

=head1 DESCRIPTION

You can store multiple cards on a customer in order to charge the customer later. You can also store multiple debit cards on a recipient in order to transfer to those cards later.

That being said, all the methods are exactly the same as L<Net::API::Stripe::Connect::ExternalAccount::Card> so this module inherits 100% from it.

The only reason why I am keeping it here, ie because Stripe makes a distinction as mentioned above.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/cards>, L<https://stripe.com/docs/sources/cards>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
