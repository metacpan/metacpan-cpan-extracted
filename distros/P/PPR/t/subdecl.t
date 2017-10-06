use warnings;
use strict;

use B::Deparse;
use Test::More;
use PPR;

plan tests => 4;

my $subdecl = qr{ ^ (?&PerlSubroutineDeclaration) $  $PPR::GRAMMAR }x;

ok 'AUTOLOAD {}' =~ $subdecl, 'AUTOLOAD';
ok 'DESTROY {}'  =~ $subdecl, 'DESTROY';
ok '&DESTROY();' !~ $subdecl, '&DESTROY();';
ok 'DESTROY();'  =~ $subdecl, 'DESTROY();';


done_testing();

