BEGIN {
    unshift(@INC, "./lib");
}

require 5.004_05;
use Test::More tests => 22;
use_ok("Net::HL7::Segment");
use_ok("Net::HL7");

# Basic stuff
#
my $seg = new Net::HL7::Segment("PID");
$seg->setField(0, "XXX");
$seg->setField(3, "XXX");

ok($seg->getField(0) eq "PID", "Field 0 is PID");
ok($seg->getName() eq "PID", "Segment name is PID");
ok($seg->getField(3) eq "XXX", "Field 3 is XXX");

# Try faulty constructors
#
ok(! defined(new Net::HL7::Segment()), "Segment constructor with no name");
ok(! defined( new Net::HL7::Segment("XXXX")), "Segment constructor with 4 char name");
ok(! defined(new Net::HL7::Segment("xxx")), "Segment constructor with lowercase name");


$seg = new Net::HL7::Segment("DG1", [4,3,2,[1,2,3],0]);

ok($seg->getField(3) eq "2", "Constructor with array ref");

my @comps = $seg->getField(4);

ok($comps[2] eq "3", "Constructor with array ref for composed fields");


# Field setters/getters
#
$seg = new Net::HL7::Segment("DG1");

$seg->setField(3, [1, 2, 3]);
$seg->setField(8, $Net::HL7::NULL);

ok(ref($seg->getField(3)) eq "ARRAY", "Composed field 1^2^3");
ok($seg->getField(8) eq "\"\"" && $seg->getField(8) eq $Net::HL7::NULL, "HL7 NULL value");
my @subFields = $seg->getField(3);

ok(@subFields == 3, "Getting composed fields as array");

ok($subFields[1] eq "2", "Getting single value from composed field");

my @flds = $seg->getFields();

ok(@flds == 9, "Number of fields in segment");

@flds = $seg->getFields(2);

ok(@flds == 7, "Getting all fields from 2nd index");

@flds = $seg->getFields(2, 4);

ok(@flds == 3, "Getting fields from 2 till 4");

$seg->setField(12);

ok($seg->size() == 8, "Size operator");

$seg->setField(12, "x");

ok($seg->size() == 12, "Size operator");

$seg->setField(8, "a");

ok($seg->getFieldAsString(8) eq "a", "Get field as string");

$seg->setField(8, ["a", "b"]);

ok($seg->getFieldAsString(8) eq "a^b", "Get field as string, components");

$seg->setField(8, ["a", ["b", "c"]]);

ok($seg->getFieldAsString(8) eq "a^b&c", "Get field as string, subcomponents");

