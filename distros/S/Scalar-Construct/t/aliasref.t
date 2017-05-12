use warnings;
use strict;

use Test::More tests => 25;

BEGIN { use_ok "Scalar::Construct", qw(aliasref); }

eval { aliasref(123) }; like $@, qr/\Anot a scalar reference/;
eval { aliasref([]) }; like $@, qr/\Anot a scalar reference/;

sub refgen { \$_[0] }

my $vv = 123;
my $v = aliasref(\$vv);
is ref($v), "SCALAR";
is $$v, 123;
ok $v == \$vv;
ok \$$v == $v;
ok refgen($$v) == $v;
eval { $$v = 456 }; is $@, "";
is $$v, 456;
is $vv, 456;

my @a = (123);
my $a = aliasref(\$a[0]);
is ref($a), "SCALAR";
is $$a, 123;
ok $a == \$a[0];
ok \$$a == $a;
ok refgen($$a) == $a;
eval { $$a = 456 }; is $@, "";
is $$a, 456;
is_deeply \@a, [456];

my $uu = \undef;
my $u = aliasref($uu);
is ref($u), "SCALAR";
is $$u, undef;
ok $u == $uu;
ok \$$u == $u;
eval { $$u = 456 }; like $@, qr/\AModification of a read-only value /;
is $$u, undef;

1;
