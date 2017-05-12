#Test that the parser can parse a wide variety of productions
use strict;
use warnings;
use Test::More 0.88;
use t::parser::TestSoarProdParser;

use Soar::Production::Parser;
use FindBin qw($Bin);
use Path::Tiny;

my $big_soar = path( $Bin,'examples', 'big.soar' );
my $parser = Soar::Production::Parser->new();
my $productions = $parser->productions(file => $big_soar, parse => 0);
plan tests => 1 + @$productions;

note('Testing parser\'s ability to parse all productions in examples/big.soar');
is($#$productions,821,'Found 822 productions in examples/big.soar');

for my $prod(@$productions){
	$prod =~ /sp \{(.*)/;
	ok(defined $parser->parse_text($prod), $1);
}