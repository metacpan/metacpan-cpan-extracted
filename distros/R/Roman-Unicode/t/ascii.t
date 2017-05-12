use 5.014;
use strict;
use warnings;
use open IO => ':utf8';
use utf8;
use vars qw( %roman2perl );

use Test::More;

if( Test::Builder->VERSION < 2 ) {
	foreach my $method ( qw(output failure_output) ) {
		binmode Test::More->builder->$method(), ':encoding(UTF-8)';
		}
	}

use_ok( 'Roman::Unicode' );

BEGIN{
%roman2perl = qw(
	Ⅰ       I
	ⅠⅠ      II
	ⅠⅠⅠ     III
	ⅠⅤ      IV
	Ⅴ       V
	ⅤⅠⅠ     VII
	Ⅹ       X
	Ⅼ       L
	Ⅽ       C
	Ⅾ           D
	Ⅿ           M
	ⅯⅭⅮⅩⅬⅠⅤ     MCDXLIV
	ⅯⅯⅤⅠⅠ       MMVII
	ↁ           |\)\)
	ↂↈ	        ((|))(((|)))
	ↂↈⅯↂⅤⅠⅠ   ((|))(((|)))M((|))VII
	ↇ           |\)\)\)
	ↇⅤⅠⅠ        |\)\)\)VII
	ↈↈ        (((|)))(((|)))
	ↈↈↈ      (((|)))(((|)))(((|)))
	ↂↈⅯↂ		((|))(((|)))M((|))
	ↈↈↈↂↈⅯↂⅭⅯⅩⅭⅠⅩ  (((|)))(((|)))(((|)))((|))(((|)))M((|))CMXCIX
	);
}

foreach my $roman ( sort keys %roman2perl ) {
	my $ascii = $roman2perl{$roman};

	no warnings 'utf8';
	ok( Roman::Unicode::is_roman( $roman ),         "$roman is roman"   );
	is( Roman::Unicode::to_ascii( $roman ), $ascii, "$roman is $ascii" );
	}

{
my @not_roman = qw( 0 -1 dog );

foreach my $not_roman ( @not_roman, '', 5_000_000 ) {
	ok( ! Roman::Unicode::is_roman( $not_roman ), "$not_roman is not roman" );
	ok( ! defined Roman::Unicode::to_ascii(  $not_roman ),
		"$not_roman is not a ASCII number" );
	}
}

done_testing();
