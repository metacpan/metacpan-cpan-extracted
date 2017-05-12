use strict;
use Test;

BEGIN { plan(tests => 8); }

use Money::ChangeMaker;
use Money::ChangeMaker::Denomination;
use Money::ChangeMaker::Presets;

my($cm, $denom, @ret);

# Australia test
ok( defined($cm = new Money::ChangeMaker()));
ok( defined($denom = $cm->get_preset("Australia")));
ok( $cm->denominations($denom));
ok( scalar(@ret = $cm->make_change(25612, 30000)), 8);
ok( $ret[5]->value, 20);
ok( $ret[2]->name, 'two dollar coin');
ok( $ret[7]->plural, 'five cent pieces');
ok(
	scalar $cm->make_change(25612, 30000),
	"2 twenty dollar notes, 1 two dollar coin, 1 one dollar coin, " .
	"1 fifty cent piece, 1 twenty cent piece, 1 ten cent piece and " .
	"1 five cent piece"
);
