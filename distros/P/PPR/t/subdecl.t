use warnings;
use strict;

use B::Deparse;
use Test::More;
use PPR;

plan tests => 6;

my $subdecl = qr{ ^ (?&PerlSubroutineDeclaration) $  $PPR::GRAMMAR }x;

ok 'AUTOLOAD {}' =~ $subdecl, 'AUTOLOAD';
ok 'DESTROY {}'  =~ $subdecl, 'DESTROY';
ok '&DESTROY();' !~ $subdecl, '&DESTROY();';
ok 'DESTROY();'  =~ $subdecl, 'DESTROY();';

ok 'sub protofirst :prototype($$@) ($x, $y, @z) {...}' =~ $subdecl, 'protofirst';
ok 'sub protolast  ($x, $y, @z) :prototype($$@) {...}' =~ $subdecl, 'protolast';


done_testing();

