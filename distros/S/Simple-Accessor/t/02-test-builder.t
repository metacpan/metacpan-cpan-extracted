use strict;
use warnings;

use Test::More tests => 9;
use FindBin;

use lib $FindBin::Bin. '/lib';

use_ok 'ObjectWithBuild';

my $o = ObjectWithBuild->new();
is $o->counter, 1, "counter is set to 1 using _build_counter";
is $o->counter, 1, "calling counter a second time does not trigger the builder _build_counter";

$o = ObjectWithBuild->new();
is $o->counter, 2, "counter is set to 2 using _build_counter";
for ( 1..5 ) {
	is $o->counter, 2, "counter is not increased";
}