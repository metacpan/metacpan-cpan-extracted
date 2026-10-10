#!perl
use strict;
use warnings;

use Test::More tests => 1;

require './Makefile.PL';
my %module = get_module_info();

my $module = $module{ NAME };

require_ok( $module );

diag( sprintf "Testing %s %s, Perl %s", $module, $module->VERSION, $] );

for (sort grep /\.pm\z/, keys %INC) {
   s/\.pm\z//;
   s!/!::!g;
   eval { diag(join(' ', $_, $_->VERSION || '<unknown>')) };
}
