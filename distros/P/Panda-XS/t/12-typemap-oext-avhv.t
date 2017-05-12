use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

# Class with wrapper

my $obj = new Panda::XS::Test::MyBaseAV(777);
is(ref $obj, 'Panda::XS::Test::MyBaseAV', "output OEXT_AV returns object");
$obj->[1] = 10;
is($obj->[1], 10, "OEXT_AV object is an ARRAYREF");
is($obj->val, 777, "input OEXT_AV works");
undef $obj;
is(dcnt(), 1, 'obj OEXT_AV desctructors called');

dcnt(0);
$obj = new Panda::XS::Test::MyBaseHV(888);
is(ref $obj, 'Panda::XS::Test::MyBaseHV', "output OEXT_HV returns object");
$obj->{abc} = 22;
is($obj->{abc}, 22, "OEXT_HV object is a HASHREF");
is($obj->val, 888, "input OEXT_HV works");
undef $obj;
is(dcnt(), 1, 'obj OEXT_HV desctructors called');

done_testing();
