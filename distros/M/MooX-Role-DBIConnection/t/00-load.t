#!perl
use strict;
use warnings;

use Test2::V0 '-no_srand';
use Module::Load 'load';

require './Makefile.PL';
my %module = get_module_info();

my $module = $module{ NAME };

load( $module );
ok 1, "We can load $module{ NAME }";

diag( sprintf "Testing %s %s, Perl %s", $module, $module->VERSION, $] );

for (sort grep /\.pm\z/, keys %INC) {
   s/\.pm\z//;
   s!/!::!g;
   diag(join(' ', $_, eval { $_->VERSION } || '<unknown>'));
}

done_testing;
