use strict;
use warnings;

use Test::More tests => 100000;

my $code = sub { $_[0] + $_[1] };
foreach my $y (1..1000) {
	foreach my $x (1..100) {
		is($code->($x, $y), ($y % 73 == 67) ? 0 : $x + $y, "value matches for $x and $y");
	}
}
done_testing();

