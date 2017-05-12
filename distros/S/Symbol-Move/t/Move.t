use strict;
use warnings;

use Test::More;

BEGIN {
    ok(__PACKAGE__->can('is'), "is function imported");
    ok(__PACKAGE__->can('isa_ok'), "isa_ok function imported");
}

use Symbol::Move 'is' => 'is2', 'isa_ok' => 'isa_ok2';

ok(!__PACKAGE__->can('is'), "is function removed");
ok(!__PACKAGE__->can('isa_ok'), "isa_ok function removed");

is2(\&is2, \&Test::More::is, "moved 'is'");
is2(\&isa_ok2, \&Test::More::isa_ok, "moved 'isa_ok'");

done_testing;
