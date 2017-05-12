# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $loaded;
BEGIN { $| = 1; print "1..41\n"; }
END {print "not ok 1\n" unless $loaded;}
use Softref;
use strict;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $count = 0;

sub blah::DESTROY {++$count}

sub make_circular1 {
  my ($a,$b);
  $a = bless \$b, 'blah';
  $b = \$a;
  ref2soft $a;
  return $a;
}

sub make_circular2 {
  my ($a,$b);
  $a = bless \$b, 'blah';
  $b = \$a;
  ref2soft $b;
  return $b;
}

sub make_circular11 {
  my ($b,$a);
  $a = bless \$b, 'blah';
  $b = \$a;
  ref2soft $a;
  return $a;
}

sub make_circular21 {
  my ($b,$a);
  $a = bless \$b, 'blah';
  $b = \$a;
  ref2soft $b;
  return $b;
}

{
  my $x = make_circular1;
  
  print "ok 2 # x=`$x'\n";
  
  $count == 0 && print "ok 3\n";
  $$$x eq $x && print "ok 4\n";
  
}
print "ok 5\n";
$count == 1 && print "ok 6\n";

{
  my $x = make_circular2;
  
  print "ok 7\n";
  
  $count == 1 && print "ok 8\n";
  $$$x eq $x && print "ok 9\n";
}

print "ok 10\n";
$count == 2 && print "ok 11\n";

{
  my $x = make_circular11;
  
  print "ok 12 # x=`$x'\n";
  
  $count == 2 && print "ok 13\n";
  $$$x eq $x && print "ok 14\n";
  
}
print "ok 15\n";
$count == 3 && print "ok 16\n";

{
  my $x = make_circular21;
  
  print "ok 17\n";
  
  $count == 3 && print "ok 18\n";
  $$$x eq $x && print "ok 19\n";
}

print "ok 20\n";
$count == 4 && print "ok 21\n";

my $x = make_circular1;
  
print "ok 22 # x=`$x'\n";
  
$count == 4 && print "ok 23\n";
$$$x eq $x && print "ok 24\n";

undef $x;
  
print "ok 25\n";
$count == 5 && print "ok 26\n";

$x = make_circular2;
  
print "ok 27 # x=`$x'\n";
  
$count == 5 && print "ok 28\n";
$$$x eq $x && print "ok 29\n";

undef $x;
  
print "ok 30\n";
$count == 6 && print "ok 31\n";

$x = make_circular1;
  
print "ok 32 # x=`$x'\n";
  
$count == 6 && print "ok 33\n";
$$$x eq $x && print "ok 34\n";

$x = -11;
  
print "ok 35\n";
$count == 7 && print "ok 36\n";

$x = make_circular2;
  
print "ok 37 # x=`$x'\n";
  
$count == 7 && print "ok 38\n";
$$$x eq $x && print "ok 39\n";

$x = -11;
  
print "ok 40\n";
$count == 8 && print "ok 41\n";
