use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

my ($s, $u, $r);

$s = Panda::XS::Test::BRSPStorage->new();
is($s->unit(), undef);

$u = Panda::XS::Test::MyBRUnitSP->new(200);
is(ref $u, 'Panda::XS::Test::MyBRUnitSP');
is($u->id, 311);
$u->xval(333);
is($u->xval, 333);
$s->unit($u);
$r = $s->unit;
is($r, $u);
is(ref $r, 'Panda::XS::Test::MyBRUnitSP');
is($r->id, 311);
is($r->xval, 333);
undef $r; undef $u;
is(dcnt, 0);
$s->unit(undef);
is(dcnt, 2); # with wrapper

done_testing();