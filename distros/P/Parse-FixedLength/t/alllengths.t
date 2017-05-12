# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::FixedLength;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $not = 'not ';

my $parser = Parse::FixedLength->new([qw(
 first_name:10
 last_name:10
 address:20
 size:5
)],{all_lengths=>10});

print $not unless defined $parser;
print "ok 2\n";

my $data = 'Bob       Jones     1122 Main XLARGE';
my $href =  $parser->parse($data);

print $not unless $href->{first_name} eq 'Bob';
print "ok 3\n";

print $not unless $href->{last_name} eq 'Jones';
print "ok 4\n";

print $not unless $href->{address} eq '1122 Main';
print "ok 5\n";

print $not unless $href->{size} eq 'XLARGE';
print "ok 6\n";

print $not unless $parser->length == 40;
print "ok 7\n";

print $not unless $parser->length('first_name') == 10;
print "ok 8\n";
