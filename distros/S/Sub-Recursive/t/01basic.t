use Test::More tests => 1 + 4;
BEGIN { require_ok('Sub::Recursive') };

#########################

use strict;

BEGIN { use_ok('Sub::Recursive') };

my $fac = recursive { $_[0] ? $_[0] * $REC->($_[0]-1) : 1 };

is($fac->(5), 120, 'main, $fac->(5)');

is(recursive { $_[0] ? $_[0] * $REC->($_[0]-1) : 1 }->(5), 120, 'inline fac');

package Foo;
::is($fac->(5), 120, 'Foo, $fac->(5)');
