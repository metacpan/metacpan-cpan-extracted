use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

$bart = $bart;
$marge = $marge;

$kids = Set::Object->new($bart, $lisa, $maggie);
$females = Set::Object->new($marge, $lisa, $maggie);
$babies = Set::Object->new($maggie);

print "1..6\n";

print 'not ' unless $kids->intersection($females) == Set::Object->new($lisa, $maggie);
print "ok 1\n";

print 'not ' unless $kids->intersection($females, $babies) == Set::Object->new($maggie);
print "ok 2\n";

print 'not ' unless $kids * $females == Set::Object->new($lisa, $maggie);
print "ok 3\n";

print 'not ' unless $kids * $females == $females * $kids;
print "ok 4\n";

print 'not ' unless $kids * $kids == $kids;
print "ok 5\n";

print 'not ' unless ($kids * Set::Object->new())->size == 0;
print "ok 6\n";

print "# size = ".($kids * Set::Object->new())->size."\n";

