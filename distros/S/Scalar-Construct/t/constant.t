use warnings;
use strict;

use Test::More tests => 28;

BEGIN { use_ok "Scalar::Construct", qw(constant); }

sub refgen { \$_[0] }

my $c = constant(123);
is ref($c), "SCALAR";
is $$c, 123;
ok \$$c == $c;
ok refgen($$c) == $c;
eval { $$c = 456 }; like $@, qr/\AModification of a read-only value /;
is $$c, 123;

my $u = constant(undef);
is ref($u), "SCALAR";
is $$u, undef;
ok \$$u == $u;
eval { $$u = 456 }; like $@, qr/\AModification of a read-only value /;
is $$u, undef;

my $s = constant(\123);
is ref($s), "REF";
is_deeply $$s, \123;
ok \$$s == $s;
ok refgen($$s) == $s;
eval { $$s = 456 }; like $@, qr/\AModification of a read-only value /;
is_deeply $$s, \123;

my $a = constant([123]);
is ref($a), "REF";
is_deeply $$a, [123];
ok \$$a == $a;
ok refgen($$a) == $a;
$$a->[0] = 456;
is_deeply $$a, [456];
push @{$$a}, 789;
is_deeply $$a, [456,789];
eval { $$a = 456 }; like $@, qr/\AModification of a read-only value /;
is_deeply $$a, [456,789];

my $destroyed = 0;
sub End::DESTROY { $destroyed = 1; }
my $o = constant(bless({}, "End"));
is $destroyed, 0;
$o = undef;
is $destroyed, 1;

1;
