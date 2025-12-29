use Test::More;
use Number::Finance::Human qw/:all/;
use strict;

$\ = "\n"; $, = "\t";

ok(to_human(10050000) eq "10.05M", "to_human");

ok(to_number("10.05M") == 10050000, "to_number million");
ok(to_number("10.05B") == 10050000000, "to_number billion");
ok(to_number("10.05Z") == 0, "to_number invalid");
ok(to_number("10.05kg") == 10050, "to_number addl chars");
ok(to_number("10.05Kg") == 10050, "to_number addl chars case insesnsitive");

done_testing();

__DATA__
