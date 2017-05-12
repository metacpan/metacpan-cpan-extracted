use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

use FindBin;
use lib $FindBin::Bin;

BEGIN { use_ok('PPI::Transform::Sequence'); }

throws_ok { PPI::Transform::Sequence->new('Trans1'); } qr/Odd number of arguments are specified/, 'check odd number';
throws_ok { PPI::Transform::Sequence->new(Trans1 => 'arg'); } qr/The latter of pairs SHOULD be an array reference/, 'check array reference';
throws_ok { PPI::Transform::Sequence->new(NotExistent => []); } qr/can't be loaded/, 'check failure of require';
throws_ok { PPI::Transform::Sequence->new(NotTrans => []); } qr/The former of pairs SHOULD be a name of PPI::Transform subclass: /, 'check isa PPI::Transform';

my $trans = PPI::Transform::Sequence->new(
    Trans1 => [ sub { s/foo/bar/g } ],
    Trans2 => [ sub { s/bar/zot/g } ]
);
is(ref($trans), 'PPI::Transform::Sequence');
is(ref($trans->idx(0)), 'Trans1');
is(ref($trans->idx(1)), 'Trans2');

my $got = <<'EOF';
sub func { return 'foo'; }
EOF

my $expected = <<'EOF';
sub func { return 'zot'; }
EOF

ok($trans->apply(\$got));
is($got, $expected);
