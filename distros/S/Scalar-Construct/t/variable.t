use warnings;
use strict;

use Test::More tests => 30;

BEGIN { use_ok "Scalar::Construct", qw(variable); }

sub refgen { \$_[0] }

my $c = variable(123);
is ref($c), "SCALAR";
is $$c, 123;
ok \$$c == $c;
ok refgen($$c) == $c;
eval { $$c = 456 }; is $@, "";
is $$c, 456;

my $u = variable(undef);
is ref($u), "SCALAR";
is $$u, undef;
ok \$$u == $u;
eval { $$u = 456 }; is $@, "";
is $$u, 456;

my $s = variable(\123);
is ref($s), "REF";
is_deeply $$s, \123;
ok \$$s == $s;
ok refgen($$s) == $s;
eval { $$s = 456 }; is $@, "";
is_deeply $$s, 456;

my $a = variable([123]);
is ref($a), "REF";
is_deeply $$a, [123];
ok \$$a == $a;
ok refgen($$a) == $a;
$$a->[0] = 456;
is_deeply $$a, [456];
push @{$$a}, 789;
is_deeply $$a, [456,789];
eval { $$a = 456 }; is $@, "";
is_deeply $$a, 456;

my $destroyed;
sub End::DESTROY { $destroyed = 1; }

$destroyed = 0;
my $o = variable(bless({}, "End"));
is $destroyed, 0;
$o = undef;
is $destroyed, 1;

$destroyed = 0;
my $p = variable(bless({}, "End"));
is $destroyed, 0;
$$p = 456;
is $destroyed, 1;

1;
