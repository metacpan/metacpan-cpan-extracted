#Test that the printer prints each production in big.soar with exactly the same structure
use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use Soar::Production::Parser;
use Soar::Production::Printer qw(tree_to_text);
use FindBin qw($Bin);
use Path::Tiny;

my $datafile = path( $Bin, 'big.soar');

my $parser = Soar::Production::Parser->new();
my $productions = $parser->productions(file => $datafile, parse => 0);
plan tests => 1 + @$productions;

is(scalar @$productions,822,'Found 822 productions in big.soar');

note('Testing printer\'s ability to correctly print all productions in big.soar');

# parse each prod in big.soar; then print and reparse.
# Compare the parses deeply to make sure nothing was
# structurally changed in printing.
my ($name, $parsed, $printed, $reparsed);
for my $prod(@$productions){
	$prod =~ /sp \{(.*)/;
	$name = $1;
	$parsed = $parser->parse_text($prod);
	$printed = tree_to_text($parsed);
	$reparsed = $parser->parse_text($printed);

	cmp_deeply($parsed, $reparsed, $name)
		or note "original:\n" . $prod . "\nprinted:\n" . $printed;
}