# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use SerialNumber::Sequence;
use Data::Dumper;
$loaded = 1;
print "ok 1\n";

###################################
print '-' x 80 ,"\n";
print "new object $ss \n";
my $ss = new SerialNumber::Sequence;
###################################
print '-' x 80 ,"\n";
print "given array by ref: [23,24,25,26,34,35,36,45,46,79,88]\n";
my $default_return_string = $ss->from_list([23,24,25,26,34,35,36,45,46,79,88]);
print "return readable string: '", $default_return_string ,"'\n";

###################################
print '-' x 80 ,"\n";
$ss->number_length(3);
$ss->prefix('&');
my $string = $ss->from_list([23,24,25,26,34,35,36,45,46,79,88]);
print "after set number_length=3, prefix=\& \n";
print "return : '", $string ,"'\n";

###################################
print '-' x 80 ,"\n";
print "given string: '$string'\n";
my @list = $ss->from_string($string);
print "return [", join( ',', @list) ,"]\n";

print "OK\n";
