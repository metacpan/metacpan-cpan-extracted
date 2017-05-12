# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::FixedLength;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
my $not = 'not ';

# Bad start-end at last_name, but don't we don't care
my $parser = Parse::FixedLength->new([
    seq_id     => '10:1:10',
    first_name => '10:11:20',
    last_name  => '10:22:30',
    country    =>  '3:31:33',
    widgets_this_year => '10R:34:43',
    zip => '10:44:53',
], {no_validate=>1});

print $not unless $parser;
print "ok 2\n";

# Same bad format, but we do care
$parser = eval { Parse::FixedLength->new([
    seq_id     => '10:1:10',
    first_name => '10:11:20',
    last_name  => '10:22:30',
    country    =>  '3:31:33',
    widgets_this_year => '10R:34:43',
    zip => '10:44:53',
]) };

print $not unless $@ and $@ =~ /Bad start position/;
print "ok 3\n";

# Another bad format, error in end
$parser = eval { Parse::FixedLength->new([
    seq_id     => '10:1:10',
    first_name => '10:11:20',
    last_name  => '10:21:29',
    country    =>  '3:31:33',
    widgets_this_year => '10R:34:43',
    zip => '10:44:53',
]) };

print $not unless $@ and $@ =~ /Bad length/;
print "ok 4\n";
