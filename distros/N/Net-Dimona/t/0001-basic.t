use strict;
use warnings;
use Test::More tests => 4;

use Net::Dimona;
pass 'Net::Dimona loaded successfully';

ok my $dimona = Net::Dimona->new( api_key => 123 );

isa_ok $dimona, 'Net::Dimona';

can_ok $dimona, qw(
    create_order list_orders get_order get_order_tracking
    get_order_timeline product_availability quote_shipping
);
