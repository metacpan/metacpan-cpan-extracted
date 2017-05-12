use strict;
use warnings;

use Test::More;

BEGIN {
    ok(__PACKAGE__->can('is'), "is function imported");
    ok(__PACKAGE__->can('isa_ok'), "isa_ok function imported");
}

use Symbol::Delete 'is', 'isa_ok';

ok(!__PACKAGE__->can('is'), "is function deleted");
ok(!__PACKAGE__->can('isa_ok'), "isa_ok function deleted");

done_testing;
