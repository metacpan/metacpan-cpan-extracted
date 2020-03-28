##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Charge/List.pm
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
package Net::API::Stripe::Charge::List;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::List );
    our( $VERSION ) = '0.1';
};

# sub data { shift->_set_get_object_array( 'data', 'Net::API::Stripe::Charge', @_ ); }

1;

__END__

