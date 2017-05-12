# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use MySQL::DateFormat;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $md = MySQL::DateFormat->new(format => 'us', informal => 1);
my $human = '3/12/2002';
my $mysql = '2002-03-12';

my $two = $md ? '' : 'not ';
print $two . "ok 2\n";

my $three = $md->toMySQL($human) eq $mysql ? '' : 'not ';
print $three . "ok 3\n";

my $four = $md->frMySQL($mysql) eq $human ? '' : 'not ';
print $four . "ok 4\n";
