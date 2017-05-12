# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::KeyboardDistanceXS qw( :all );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
&computeDistance(2, 0,     0);
&computeDistance(3, 0,     0,      "","");
&computeDistance(4, 1,     0,      "This","This");
&computeDistance(5, 0.985, 0.001,  "Apple","wpple");
&computeDistance(6, 0.405, 0.001,  "A short string","A longer string, by far");

sub computeDistance
{
  my($test,$expected,$epsilon,$a,$b) = @_;
  my $dist = qwertyKeyboardDistance($a,$b);
  my $siml = qwertyKeyboardDistanceMatch($a,$b);
  my $diff = abs($siml - $expected);
  my $rv = $diff <= $epsilon;
  #print "distance $a,$b: $dist => $siml : eps:$epsilon diff:$diff\n";
  print $rv ? "ok $test\n" : "not ok $test\n";
}
