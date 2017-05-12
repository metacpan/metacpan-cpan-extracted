use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

use vars qw( $homer $marge $bart $lisa $maggie );

$simpsons = Set::Object->new( $homer, $marge, $bart, $lisa, $maggie );
$parents = Set::Object->new( $homer, $marge );
$empty = Set::Object->new();

print "1..14\n";

print 'not ' unless $parents < $simpsons;
print "ok 1\n";

print 'not ' if $simpsons < $parents;
print "ok 2\n";

print 'not ' if $parents < $parents;
print "ok 3\n";

print 'not ' unless $parents <= $simpsons;
print "ok 4\n";

print 'not ' unless $parents <= $parents;
print "ok 5\n";

print 'not ' unless $empty < $simpsons;
print "ok 6\n";

print 'not ' unless $empty <= $simpsons;
print "ok 7\n";

print 'not ' unless $simpsons > $parents;
print "ok 8\n";

print 'not ' if $parents > $simpsons;
print "ok 9\n";

print 'not ' if $simpsons > $simpsons;
print "ok 10\n";

print 'not ' unless $simpsons >= $parents;
print "ok 11\n";

print 'not ' unless $simpsons >= $simpsons;
print "ok 12\n";

print 'not ' unless $parents > $empty;
print "ok 13\n";

print 'not ' unless $parents >= $empty;
print "ok 14\n";
