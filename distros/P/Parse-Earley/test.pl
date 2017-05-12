#!/usr/bin/perl

use Test::Simple tests => 10;

use Parse::Earley;
use Data::Dumper;

my $parser = new Parse::Earley;
my ($grammar, $input);

#Test creation

ok(defined $parser,                 'new()');
ok($parser->isa('Parse::Earley'));

#Test basic, unambiguous grammar

$grammar = <<'EOG';
S: E
E: T '+' E
E: T
T: /\d+/
EOG
$input = '1+2+3';

$parser->grammar($grammar);
$parser->start('S');

#Run it exactly as many times as necessary
for (1..6) {
    $parser->advance($input);
}
ok($parser->matches_all($input, 'S'),  'simple grammar');

#Test funky syntax with calculator grammar

$grammar = <<'EOG';
#This is a calculator
S: E        # Main rule
            # Blank line
E: E        # First match
   '+' T    # Term
  |E'-'T    # Minus symbol
|      T    # Or just regular term
T: m#\d+#   # Comment-like m//
EOG
$input = '1+2-415657+3';

$parser = new Parse::Earley;        # Clear previous grammar
$parser->grammar($grammar);
$parser->start('S');

for (1..8) {
    $parser->advance($input);
}
ok($parser->matches_all($input, 'S'),   'funky-syntax grammar');

#Test terminal seperators

$grammar = <<'EOG';
S: E
E: E <noskip> '+' T | T        # No spaces before +
T: /\d+/
EOG
$input = '1+2+ 3+  4';

$parser = new Parse::Earley;            # Clear previous grammar
$parser->grammar($grammar);
$parser->start('S');

for (1..8) {
    $parser->advance($input);
}
ok($parser->matches_all($input, 'S'),   'terminal seperator');

$input = '1+2 +3+ 4+5';                 # This one's invalid
$parser->start('S');                    # Re-initialize

for (1..5) {                            # We only need 5 to fail
    $parser->advance($input);
}
ok($parser->fails($input, 'S'),        'same, with bad input');

# Ambiguous grammar

$grammar = <<'EOG';
S: D
D: D | 'a'
EOG
$input = 'a';

$parser = new Parse::Earley;
$parser->grammar($grammar);
$parser->start('S');

for (1..2) {
    $parser->advance($input);
}
my ($tree) = $parser->matches_all($input, 'S');
ok($tree,  'ambiguous grammar: matches');

ok($tree->{down}[1]{down}[0] == $tree->{down}[0], 'circular parse graph');

# | inside quotes
$grammar = <<'EOG';
S: E
E: E '|' T | T
T: /\w+/
EOG
$input = 'al|bum |   co| ver';
$parser = new Parse::Earley;
$parser->grammar($grammar);
$parser->start('S');

for (1..9) {
    $parser->advance($input);
}
ok($parser->matches_all($input, 'S'), '"|" inside quotes');

# \ inside literals
$grammar = <<'EOG';
S: E
E: E '\'' T | T
T: /\w/
EOG
$input = "f' o'u   ' s'b'a'r";
$parser = new Parse::Earley;
$parser->grammar($grammar);
$parser->start('S');

for (1..14) {
    $parser->advance($input);
}
ok($parser->matches_all($input, 'S'), "'\\'' in literal");
