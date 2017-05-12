use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 40;
use Perlmazing;

my @arr = (0..9);

for my $i (0..19) {
	my $r = in_array @arr, $i;
	if ($i <= 9) {
		my $true = $r ? 1 : 0;
		is $true, 1, 'found in array';
		is (($r == $i), 1, 'correct return value');
	} else {
		my $true = $r ? 1 : 0;
		is $true, 0, 'not found in array';
		is $r, '', 'correct return value';
	}
}
