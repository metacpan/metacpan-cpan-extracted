#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Personality::Type::MBTI' );
}

diag( "Testing Personality::Type::MBTI $Personality::Type::MBTI::VERSION, Perl $], $^X" );
