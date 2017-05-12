use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

$simpsons = Set::Object->new();

print "1..3\n";

print 'not ' if $simpsons->members();
print "ok 1\n";

@members1 = @simpsons;
@members1 = sort { $a->{firstname} cmp $b->{firstname} } @members1;

$simpsons->insert(@members1);
@members2 = $simpsons->members();

print 'not ' unless @members2 == 5;
print "ok 2\n";

@members2 = sort @members2;

foreach $member1 (@members1)
{
   my $foo = shift(@members2);
   unless ($member1 == $foo) { print 'not '; last }
}

print "ok 3\n";
