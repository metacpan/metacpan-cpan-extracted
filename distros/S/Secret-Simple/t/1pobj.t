
use Test::Simple tests => 1;

use Secret::Simple;

my $KEY = 'This is a test key';
my $TXT = <<EOF;
A human being should be able to change a diaper, plan an invasion,
butcher a hog, design a building, conn a ship, write a sonnet,
balance accounts, build a wall, set a bone, comfort the dying, take
orders, give orders, cooperate, act alone, solve an equation, analyze
a new problem, pitch manure, program a computer, cook a tasty meal,
fight efficiently, die gallantly. Specialization is for insects.
-- Robert A. Heinlein
EOF

my $ss = Secret::Simple->new( $KEY );
my $ciphertext = $ss->encrypt( $TXT );
my $plaintext  = $ss->decrypt( $ciphertext );

ok ( $plaintext eq $TXT );

