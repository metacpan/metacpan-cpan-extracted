# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 10 };
use TERN::it;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$outer->{inner}->{name}='fred';

defined_it $outer->{inner}->{name} and it eq 'fred' and ok(2);

#print "A:",it,"\n";

exists_it %{$outer}, 'inner' and ok(3);

#print "B:",it,"@{[%{it()}]}\n";
exists_it %{it()}, 'name' and ok(4);
it eq 'fred' and ok(5);

#print "D:",it,"\n";
exists_it %outer, 'limits' or ok(6);

#print "E:",it,"\n";
@outer=(1,2,3);

exists_itA @outer,2 and ok(7);
#print "F:",it,"\n";
exists_itA @outer,22 or ok(8);
#print "G:",it,"\n";
defined_it $outer[5] or ok(9);
#print "H:",it,"\n";
defined_it $outer[1] and it==2 and  ok(10);
#print "I:",it,"\n";

