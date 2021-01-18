use 5.014;
use strict;
use warnings;
use open qw(:std :utf8);
use utf8;
use vars qw( %roman2perl );

use Test::More 1.0;

diag( "Test::Builder " . Test::Builder->VERSION );
if( Test::Builder->VERSION < 2 ) {
	foreach my $method ( qw(output failure_output todo_output) ) {
		binmode Test::More->builder->$method(), ':encoding(UTF-8)';
		}
	}

# Need to load this before Unicode::Casing
BEGIN { use_ok( 'Roman::Unicode' ) }

my %upper2lower = qw(
	Ⅰ       ⅰ
	ⅠⅠ       ⅰⅰ
	ⅠⅠⅠ      ⅰⅰⅰ
	ⅠⅤ      ⅰⅴ
	Ⅴ       ⅴ
	ⅤⅠⅠ     ⅴⅰⅰ
	Ⅹ       ⅹ
	Ⅼ       ⅼ
	Ⅽ       ⅽ
	Ⅾ           ⅾ
	Ⅿ           ⅿ
	ⅯⅭⅮⅩⅬⅠⅤ     ⅿⅽⅾⅹⅼⅰⅴ
	ⅯⅯⅤⅠⅠ       ⅿⅿⅴⅰⅰ
	ↈↈ        (((|)))(((|)))
	ↂↈ	        ((|))(((|)))
	ↂↈⅯↂ		((|))(((|)))ⅿ((|))
	ↂↈⅯↂⅤⅠⅠ   ((|))(((|)))ⅿ((|))ⅴⅰⅰ
	ↈↈↈ      (((|)))(((|)))(((|)))
	);

SKIP: {
	my $count = keys %upper2lower;
	skip "Unicode::Casing not installed!", $count unless eval <<'HERE';
		use Unicode::Casing lc => \\&Roman::Unicode::to_roman_lower;
		foreach my $upper ( sort keys %upper2lower ) {
			my $lower = $upper2lower{$upper};
			is( Roman::Unicode::to_roman_lower( $upper ), $lower, "$upper turns into $lower (to_roman_lower)"   );
			is( lc $upper, $lower, "$upper turns into $lower (lc)"   );
			}
		};
HERE
	}


done_testing();
