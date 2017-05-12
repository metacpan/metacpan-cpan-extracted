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
	ⅰ       1
	ⅰⅰ      2
	ⅰⅴ      4
	ⅴ       5
	ⅹ       10
	ⅼ       50
	ⅽ       100
	ⅾ       500
	ⅿ       1000
	Ⅰ       1
	ⅠⅠ       2
	ⅠⅠⅠ      3
	ⅠⅤ      4
	Ⅴ       5
	ⅤⅠⅠ      7
	Ⅹ       10
	Ⅼ       50
	Ⅽ       100
	Ⅾ           500
	Ⅿ           1000
	ⅯⅭⅮⅩⅬⅠⅤ     1444
	ⅯⅯⅤⅠⅠ       2007
	ↈↈ        200000
	ↂↈ	        90000
	ↂↈⅯↂ		99000
	ↂↈⅯↂⅤⅠⅠ   99007
	ↈↈↈ      300000
	ↈↈↈↂↈⅯↂⅭⅯⅩⅭⅠⅩ  399999
	);
}

foreach my $roman ( sort keys %roman2perl ) {
	my $number = $roman2perl{$roman};

	no warnings 'utf8';
	ok( Roman::Unicode::is_roman( $roman  ),            "$roman is roman"   );
	is( Roman::Unicode::to_perl(  $roman  ), $number,   "$roman is $number" );
	is( Roman::Unicode::to_roman( $number ), uc $roman, "$number is $roman" );
	}

{
my @not_roman = qw( 0 -1 dog Ⅰⅴ );

foreach my $not_roman ( @not_roman, '', 5_000_000 ) {
	ok( ! Roman::Unicode::is_roman( $not_roman ), "$not_roman is not roman" );
	ok( ! defined Roman::Unicode::to_roman(  $not_roman ),
		"$not_roman is not a Perl number" );
	ok( ! defined Roman::Unicode::to_perl(  $not_roman ),
		"$not_roman is not a Perl number" );
	}
}

done_testing();
