use warnings;
use strict;

use B::Deparse;
use Test::More;
use PPR;

plan tests => 7;

my $subdecl = qr{ ^ (?&PerlSubroutineDeclaration) $  $PPR::GRAMMAR }x;

ok 'AUTOLOAD {}' =~ $subdecl, 'AUTOLOAD';
ok 'DESTROY {}'  =~ $subdecl, 'DESTROY';
ok '&DESTROY();' !~ $subdecl, '&DESTROY();';
ok 'DESTROY();'  =~ $subdecl, 'DESTROY();';

ok 'sub protofirst :prototype($$@) ($x, $y, @z) {...}' =~ $subdecl, 'protofirst';
ok 'sub protolast  ($x, $y, @z) :prototype($$@) {...}' =~ $subdecl, 'protolast';

ok 'sub unnamed  ($, $y) {...}' =~ $subdecl, 'unnamed';


done_testing();

