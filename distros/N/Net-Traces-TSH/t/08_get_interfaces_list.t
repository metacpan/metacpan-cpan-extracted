# Test correct operation of Net::Traces::TSH get_interfaces_list()
#
use strict;
use warnings;
use Test;

BEGIN { plan tests => 7 };

use Net::Traces::TSH 0.13 qw( process_trace get_interfaces_list );
ok(1);

process_trace 't/sample_input/sample.tsh' and ok(1);

foreach ( get_interfaces_list ) {
  ok(1);
}

my @interfaces = get_interfaces_list;

ok( 1 == shift @interfaces);

ok( 2 == shift @interfaces);

ok( 2 == get_interfaces_list);
