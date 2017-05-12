use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

$simpsons = Set::Object->new(@simpsons);

print "1..2\n";

$simpsons->clear();
print 'not' unless $simpsons->size() == 0;
print "ok 1\n";

$simpsons->insert(@simpsons);
print 'not' unless $simpsons->size() == @simpsons;
print "ok 2\n";
