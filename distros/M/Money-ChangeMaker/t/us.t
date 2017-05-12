use strict;
use Test;

BEGIN { plan(tests => 7); }

use Money::ChangeMaker;
use Money::ChangeMaker::Denomination;
use Money::ChangeMaker::Presets;

my($cm, $denom, @ret);

# General tests & test of US currency
ok( defined($cm = new Money::ChangeMaker()));
ok( scalar(@ret = $cm->make_change(1521, 2000)) == 11);
ok( $ret[0]->value == 100);
ok( $ret[4]->name eq 'quarter');
ok( $ret[8]->plural eq 'pennies');
ok( $cm->as_string(@ret) eq "4 dollar bills, 3 quarters and 4 pennies");
ok(
	scalar $cm->make_change(1521, 2000) eq
	"4 dollar bills, 3 quarters and 4 pennies"
);
