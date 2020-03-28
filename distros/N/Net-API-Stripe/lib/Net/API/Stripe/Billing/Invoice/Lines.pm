##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice/Lines.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Invoice::Lines;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::List );
    our( $VERSION ) = '0.1';
};

# Inherited
# sub object { shift->_set_get_scalar( 'object', @_ ); }

## Array of Net::API::Stripe::Billing::Invoice::LineItem
# sub data { shift->_set_get_object_array( 'data', 'Net::API::Stripe::Billing::Invoice::LineItem', @_ ); }

# Inherited
# sub has_more { shift->_set_get_scalar( 'has_more', @_ ); }

# Inherited
# sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

