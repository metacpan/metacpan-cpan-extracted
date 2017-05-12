use strict;
use Test;

BEGIN { plan(tests => 8); }

use Money::ChangeMaker;
use Money::ChangeMaker::Denomination;
use Money::ChangeMaker::Presets;

my($cm, $denom, @ret);

# Canada test
ok( defined($cm = new Money::ChangeMaker()));
ok( defined($denom = $cm->get_preset("Canada")));
ok( $cm->denominations($denom));
ok( scalar(@ret = $cm->make_change(25612, 30000)), 11);
ok( $ret[9]->value, 1);
ok( $ret[2]->name, 'two dollar coin');
ok( $ret[5]->plural, 'quarters');
ok(
	scalar $cm->make_change(25612, 30000),
	"2 twenty dollar bills, 1 two dollar coin, 1 one dollar coin, " .
	"3 quarters, 1 dime and 3 pennies"
);
