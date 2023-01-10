use Test::Most tests => 2;

use lib "t/lib";

use StructLess;

use Role::Tiny::MonkeyPatch qw/StructLess/;

my $s = StructLess->new->with_roles("+Something");

ok($s->can("snorg"), "load non-hash-based");
ok($s->snorg(12) eq "StructLess::Role::Something", "load non-hash-based")
