use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

$simpsons = Set::Object->new($homer, $marge);
$bouviers = Set::Object->new($marge, $patty, $selma);
$simpsons_only = Set::Object->new($homer);
$bouviers_only = Set::Object->new($patty, $selma);
$empty = Set::Object->new;

print "1..5\n";

print 'not ' unless $simpsons->difference($bouviers) == $simpsons_only;
print "ok 1\n";

print 'not ' unless $simpsons - $bouviers == $simpsons_only;
print "ok 2\n";

print 'not ' unless $simpsons - $simpsons == $empty;
print "ok 3\n";

print 'not ' unless $simpsons_only  - $bouviers_only == $simpsons_only;
print "ok 4\n";

print 'not ' unless $simpsons - $empty == $simpsons;
print "ok 5\n";
