use warnings;
use strict;

use Test::More tests => 23;

BEGIN { use_ok "Scalar::Construct", qw(aliasobj); }

sub refgen { \$_[0] }

my $vv = 123;
my $v = aliasobj($vv);
is ref($v), "SCALAR";
is $$v, 123;
ok $v == \$vv;
ok \$$v == $v;
ok refgen($$v) == $v;
eval { $$v = 456 }; is $@, "";
is $$v, 456;
is $vv, 456;

my @a = (123);
my $a = aliasobj($a[0]);
is ref($a), "SCALAR";
is $$a, 123;
ok $a == \$a[0];
ok \$$a == $a;
ok refgen($$a) == $a;
eval { $$a = 456 }; is $@, "";
is $$a, 456;
is_deeply \@a, [456];

my $uu = \undef;
my $u = aliasobj($$uu);
is ref($u), "SCALAR";
is $$u, undef;
ok $u == $uu;
ok \$$u == $u;
eval { $$u = 456 }; like $@, qr/\AModification of a read-only value /;
is $$u, undef;

1;
