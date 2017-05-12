use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

my $simpsons1 = Set::Object->new($homer, $marge);
my $simpsons2 = Set::Object->new($homer, $marge);
my $bouviers = Set::Object->new($marge, $patty, $selma, $patty, $selma);

print "1..4\n";

print 'not ' unless $simpsons1 == $simpsons1;
print "ok 1\n";

print 'not ' if $simpsons1 != $simpsons1;
print "ok 2\n";

print 'not ' unless $simpsons1 != $bouviers;
print "ok 3\n";

print 'not ' if $simpsons1 == $bouviers;
print "ok 4\n";
