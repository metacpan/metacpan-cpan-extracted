use strict;
use Test;

BEGIN { plan(tests => 8); }

use Money::ChangeMaker;
use Money::ChangeMaker::Denomination;
use Money::ChangeMaker::Presets;

my($cm, $denom, @ret);

# India test
ok( defined($cm = new Money::ChangeMaker()));
ok( defined($denom = $cm->get_preset("India")));
ok( $cm->denominations($denom));
ok( scalar(@ret = $cm->make_change(256.75, 300)), 5);
ok( $ret[3]->value, 1);
ok( $ret[4]->value, 0.25);
ok( $ret[0]->name, 'twenty rupee note');
ok(
	scalar $cm->make_change(256.75, 300),
	"2 twenty rupee notes, 1 two rupee note, 1 rupee coin and 1 25 paise coin"
);
