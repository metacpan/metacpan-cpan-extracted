use strict;
use Test;

BEGIN { plan(tests => 8); }

use Money::ChangeMaker;
use Money::ChangeMaker::Denomination;
use Money::ChangeMaker::Presets;

my($cm, $denom, @ret);

# UK test
ok( defined($cm = new Money::ChangeMaker()));
ok( defined($denom = $cm->get_preset("UK")));
ok( $cm->denominations($denom));
ok( scalar(@ret = $cm->make_change(2428, 4001)) == 6);
ok( $ret[2]->value, 50);
ok( $ret[4]->name, 'two pence coin');
ok( $ret[5]->plural, 'pence');
ok(
	scalar $cm->make_change(2428, 4001),
	"1 ten pound note, 1 five pound note, 1 fifty pence coin, " .
	"1 twenty pence coin, 1 two pence coin and 1 penny"
);
