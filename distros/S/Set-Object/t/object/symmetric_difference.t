use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

$homer = $homer;
$patty = $patty;
$selma = $selma;

$simpsons = Set::Object->new($homer, $marge);
$bouviers = Set::Object->new($marge, $patty, $selma);
$trouble = Set::Object->new($homer, $patty, $selma);
$empty = Set::Object->new;

print "1..4\n";

print 'not ' unless $simpsons->symmetric_difference($bouviers) == $trouble;
print "ok 1\n";

print 'not ' unless $simpsons % $bouviers == $trouble;
print "ok 2\n";

print 'not ' unless $simpsons % $simpsons == $empty;
print "ok 3\n";

print 'not ' unless $simpsons % $empty == $simpsons;
print "ok 4\n";
