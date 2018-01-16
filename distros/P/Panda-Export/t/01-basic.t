use strict;
use warnings;
use Test::More;
BEGIN {unshift @INC, 't'}

package HereTest;
use Test::More;

# creating constants
use Panda::Export {CONST1 => 1, CONST2 => 'suka'};
ok(CONST1 == 1 and CONST2 eq 'suka');

# collision error
my $ok = eval { Panda::Export->import({CONST1 => 2}); 1 };
ok(!$ok and CONST1 == 1);

# exporting all constants
package main;
use Test::More;
use ExTest;
ok(CONST1 == 1 and CONST2 == 2);

# exporting list
package main2;
use Test::More;
use ExTest qw/CONST1 CONST3 folded pizda/;
ok(CONST1 == 1 and CONST3 == 3 and folded == 42);
ok(!eval{CONST2()});
ok(pizda() == 10 and pizda() == 11 and pizda() == 12);

# collision export error
ok(!eval { ExTest->import('CONST3') });

# exporting list + all consts
package main3;
use Test::More;
use ExTest qw/pizda :const/;
ok(CONST9 == 9 and CONST8 == 8);
ok(pizda() == 13);

# no function error
package main3;
use Test::More;
BEGIN { 
    our $ok;
    $ok = eval { ExTest->import('pizda2'); 1};
}
ok(!$ok);

# bad const names ok
package main4;
use Test::More;
ok(!eval {Panda::Export->import(\1, 1); 1}, 'bad name croaks');

done_testing();
