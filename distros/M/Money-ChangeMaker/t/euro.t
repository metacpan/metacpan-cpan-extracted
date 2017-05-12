use strict;
use Test;

BEGIN { plan(tests => 8); }

use Money::ChangeMaker;
use Money::ChangeMaker::Denomination;
use Money::ChangeMaker::Presets;

my($cm, $denom, @ret);

# Euro test
ok( defined($cm = new Money::ChangeMaker()));
ok( defined($denom = $cm->get_preset("Euro")));
ok( $cm->denominations($denom));
ok( scalar(@ret = $cm->make_change(3361, 100000)), 12);
ok( $ret[10]->value, 2);
ok( $ret[2]->name, 'two hundred euro note');
ok( $ret[7]->plural, 'twenty cent coins');
ok(
	scalar $cm->make_change(3361, 100000),
	"1 five hundred euro note, 2 two hundred euro notes, 1 fifty euro note, " .
	"1 ten euro note, 1 five euro note, 1 one euro coin, 1 twenty cent coin, " .
	"1 ten cent coin, 1 five cent coin and 2 two cent coins"
);
