BEGIN {
    unshift(@INC, "./lib");
}

require 5.004_05;
use Test::More tests => 6;

use_ok("Net::HL7::Segment");
use_ok("Net::HL7::Segments::MSH");

my $msh = new Net::HL7::Segments::MSH();

$msh->setField(1, "*");

ok($msh->getField(1) eq "*", "MSH Field sep field (MSH(1))");

$msh->setField(1, "xx");

ok($msh->getField(1) eq "*", "MSH Field sep field (MSH(1))");

$msh->setField(2, "xxxxx");

# Should have had no effect
ok($msh->getField(2) eq "^~\\&", "Special fields not changed");


# Should have had the effect of changing some separator fields
$msh->setField(2, "abcd");
ok($msh->getField(2) eq "abcd", "Encoding characters field set (MSH(2))");
