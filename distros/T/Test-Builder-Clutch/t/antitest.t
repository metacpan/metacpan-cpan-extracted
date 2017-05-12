use strict;
use warnings;

use Test::More;
use Test::Builder::Clutch;

plan tests => 24;

sub even_ok {
	ok !(shift() % 2);
}

sub odd_ok {
	ok shift() % 2;
}

sub is_zero {
	ok shift == 0;
}

sub is_nonzero {
	ok shift != 0;
}

sub is_positive {
	ok shift > 0;
}

sub is_negative {
	ok(shift() < 0);
}

sub isref_ok {
	ok ref shift;
}

sub isnotref_ok {
	ok ref shift eq '';
}

even_ok 4;
odd_ok 5;
is_zero 0;
is_nonzero 2;
is_positive 1;
is_negative -1;
isref_ok {};
isnotref_ok ();

BEGIN {
	Test::Builder::Clutch::antitest qw/even_ok odd_ok/;
}
ok even 4;
ok !even 5;
ok odd 5;
ok !odd 4;

BEGIN {
	Test::Builder::Clutch::antitest
		{ 'is_zero' => 'zero' },
		{ 'is_nonzero' => 'nonzero' };
}
ok zero 0;
ok !zero 1;
ok nonzero 1;
ok !nonzero 0;

# test one at a time
BEGIN {
	Test::Builder::Clutch::antitest 'isref_ok';
}
ok isref {};
ok !isref ();
BEGIN {
	Test::Builder::Clutch::antitest { 'is_positive' => 'positive' };
}
ok positive 1;
ok !positive -1;

# test mixed
BEGIN {
	Test::Builder::Clutch::antitest
		'isnotref_ok',
		{ 'is_negative' => 'negative' };
}
ok isnotref ();
ok !isnotref {};
ok negative -1;
ok !negative 1;
