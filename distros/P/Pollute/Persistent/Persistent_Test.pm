
package Persistent_Test;

$Runs++ and die "the body is only supposed to be required once.";

use Pollute::Persistent;
ok(1);
use Carp;
ok(2);


#print "About to pollute\n";
#Pollute;



1;
