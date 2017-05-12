use blib;
use Test::More tests => 2;
BEGIN { use_ok('Regexp::MinLength',qw(MinLength)) };

my $fail = 0;

while (<DATA>) {
	chop;
	my ($num,$pattern) = split(/\t/,$_);
	if ($num ne MinLength($pattern)) {
		$fail = 1;
	}
}

ok( $fail == 0 , 'MinLength' );

__DATA__
1	\d
0	\s*
5	a{5}
7	b{7,}
9	c{9,11}
1	^5$
1	a|b
3	bar
0	.*
6	foo(.*)bar
