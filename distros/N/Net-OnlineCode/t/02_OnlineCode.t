# -*- Perl -*-

use Test::More tests => 11;

BEGIN { use_ok('Net::OnlineCode') }

my ($obj1,$obj2);

# chosen parameters below should not modify the e value
$obj1 = new Net::OnlineCode(e => 0.01,
			    q => 3,
			    mblocks => 4000,
			    e_warning => 1);
ok(ref($obj1), "Net::OnlineCode new returns object");

ok(0.01 == $obj1->get_e, "Sufficient mblocks to prevent recalculating e");
ok($obj1->get_mblocks == 4000, "get_mblocks == supplied mblocks value");
ok($obj1->get_ablocks > 0, "non-zero number of auxiliary blocks");
ok($obj1->get_f <= $obj1->get_coblocks, "max degree <= # composite blocks");


# chosen parameters below *should* modify the e value
$obj2 = new Net::OnlineCode(e => 0.01,
			      q => 3,
			      mblocks => 400,
			      e_warning => 0);

ok(ref($obj2), "Net::OnlineCode new returns object");
ok(0.01 != $obj2->get_e, "e value recalculated");
ok($obj2->get_mblocks == 400, "get_mblocks = supplied mblocks value");
ok($obj2->get_ablocks > 0, "non-zero number of auxiliary blocks");
ok($obj2->get_f <= $obj2->get_coblocks, "max degree <= # composite blocks");

