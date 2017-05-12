use strict;
use warnings;

use Test::More tests => 5;
use PDL;
use_ok('PDL::Util', 'add_pdl_method');

my $pdl = zeros(5,5);

add_pdl_method({ 'mymethod_ref' => \&method1 });
ok($pdl->can('mymethod_ref'), "method added by code reference");

add_pdl_method({ 'mymethod_unroll' => 'unroll' });
ok($pdl->can('mymethod_unroll'), "method added by name from PDL::Util's exportable function");

add_pdl_method(['unroll', 'export2d']);
ok($pdl->can('unroll'), "'unroll' method added by array from PDL::Util's exportable function");
ok($pdl->can('export2d'), "'export2d' method added by array from PDL::Util's exportable function");

sub method1 {
  my $pdl = shift;
  return 1;
}

