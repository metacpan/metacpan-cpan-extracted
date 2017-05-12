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

###########################################################################
# Uppercase
{
my @romans = qw(
	Ⅰ ⅠⅠ ⅠⅠⅠ ⅠⅤ Ⅴ ⅤⅠⅠ Ⅹ Ⅼ Ⅽ Ⅾ Ⅿ ⅯⅭⅮⅩⅬⅠⅤ ⅯⅯⅤⅠⅠ
	ↈↈ ↂↈ ↂↈⅯↂ ↂↈⅯↂⅤⅠⅠ ↈↈↈ ↈↈↈↂↈⅯↂⅭⅯⅩⅭⅠⅩ
	);

foreach ( @romans ) {
	ok( m/\A\p{Roman::Unicode::IsRoman}+\z/, "$_ matches IsRoman" );
	ok( m/\A\p{Roman::Unicode::IsUppercaseRoman}+\z/,
		"$_ matches IsUppercaseRoman" );
	ok( ! m/\A\p{Roman::Unicode::IsLowercaseRoman}+\z/,
		"$_ does not match IsLowercaseRoman" );
	}
}

###########################################################################
# Uppercase
{
my @romans = map lc, qw(
	Ⅰ ⅠⅠ ⅠⅠⅠ ⅠⅤ Ⅴ ⅤⅠⅠ Ⅹ Ⅼ Ⅽ Ⅾ Ⅿ ⅯⅭⅮⅩⅬⅠⅤ ⅯⅯⅤⅠⅠ
	);

foreach ( @romans ) {
	ok( m/\A\p{Roman::Unicode::IsRoman}+\z/, "$_ matches IsRoman" );
	ok( m/\A\p{Roman::Unicode::IsLowercaseRoman}+\z/,
		"$_ matches IsLowercaseRoman" );
	ok( ! m/\A\p{Roman::Unicode::IsUppercaseRoman}+\z/,
		"$_ does not match IsUppercaseRoman" );
	}
}

###########################################################################
# Not
{
my @not_roman = qw( 0 -1 dog );

foreach ( @not_roman, '', 5_000_000 ) {
	ok( ! m/\A\p{Roman::Unicode::IsRoman}+\z/, "$_ does not match IsRoman" );
	ok( ! m/\A\p{Roman::Unicode::IsUppercaseRoman}+\z/,
		"$_ does not match IsUppercaseRoman" );
	ok( ! m/\A\p{Roman::Unicode::IsLowercaseRoman}+\z/,
		"$_ does not match IsLowercaseRoman" );
	}
}

done_testing();
