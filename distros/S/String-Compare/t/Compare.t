use Test;

BEGIN { plan tests => 2 }

use String::Compare;
ok(1);

my $str1 = "J R Company";
my $str2 = "J. R. Company";
my $str3 = "J R Associates";
my $points12 = compare($str1,$str2);
my $points13 = compare($str1,$str3);
if ($points12 > $points13) {
	ok(1)
} else {
	ok(0)
}
