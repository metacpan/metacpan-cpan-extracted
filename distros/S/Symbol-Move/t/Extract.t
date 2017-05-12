use strict;
use warnings;

use Test::More;

BEGIN {
    ok(__PACKAGE__->can('is'), "is function imported");
    ok(__PACKAGE__->can('isa_ok'), "isa_ok function imported");
}

my ($is, $isa_ok);
use Symbol::Extract 'is' => \$is, 'isa_ok' => \$isa_ok;

ok(!__PACKAGE__->can('is'), "is function removed");
ok(!__PACKAGE__->can('isa_ok'), "isa_ok function removed");

$is->($is, \&Test::More::is, "extracted is into a ref");
$is->($isa_ok, \&Test::More::isa_ok, "extracted is into a ref");

done_testing;
