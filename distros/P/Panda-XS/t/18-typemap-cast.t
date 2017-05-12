use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

is(Panda::XS::Test::test_typemap_incast_av([1,2,3]), 3);
is(Panda::XS::Test::test_typemap_incast_av2([1,2,3], [5,6]), 5);
is(Panda::XS::Test::test_typemap_incast_myrefcounted(new Panda::XS::Test::MyRefCounted(123456)), 123456);
cmp_deeply(Panda::XS::Test::test_typemap_outcast_av([1,2,3]), [1,1,1]);
cmp_deeply(Panda::XS::Test::test_typemap_outcast_av(undef), []);

dcnt(0);
my $ret = Panda::XS::Test::test_typemap_outcast_complex(new Panda::XS::Test::MyRefCountedChildSP(555,666));
is(dcnt(), 2);
is(ref $ret, 'ARRAY');
is(scalar @$ret, 2);
is($ret->[0], 555);
is(ref $ret->[1], 'Panda::XS::Test::MyBaseSP');
is($ret->[1]->val, 666);
undef $ret;
is(dcnt(), 3);

dcnt(0);

# TEST IN/OUT CAST WRAPPED OBJECT
$ret = Panda::XS::Test::test_typemap_outcast_wrap(234, 567);
is(ref $ret, 'Panda::XS::Test::WChild');
is($ret->val, 234);
is($ret->val2, 567);
$ret->xval2(123);
$ret->xval(321);
cmp_deeply([Panda::XS::Test::test_typemap_incast_wrap($ret)], [234, 567]);
undef $ret;
is(dcnt(), 3);

dcnt(0);

done_testing();
