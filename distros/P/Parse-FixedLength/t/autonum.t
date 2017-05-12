# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::FixedLength;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
my $not = 'not ';

# Croak on all duplicates
my $parser = eval { Parse::FixedLength->new([
    first_name => '20:1:20',
    filler     => '10:21:30',
    country    =>  '3:31:33',
    filler     => '10R:34:43',
    zip        => '10:44:53',
]) };

print $not unless $@ and $@ =~ /Duplicate field filler/;
print "ok 2\n";

# All duplicates should be ok
$parser = Parse::FixedLength->new([
    first_name => '20:1:20',
    filler     => '10:21:30',
    country    =>  '3:31:33',
    filler     => '10R:34:43',
    zip        => '10:44:53',
    filler     => '5:54:58',
], {autonum=>1});

print $not unless $parser;
print "ok 3\n";

# Parse something and check the filler fields
my $ten = "1234567890";
my $three = "123";
my $five = "12345";
my $data = ($ten x 3).$three.($ten x 2).$five;
my $href = $parser->parse($data);
print $not unless $href
              and $$href{filler_1} eq $ten
              and $$href{filler_2} eq $ten
              and $$href{filler_3} eq $five;
print "ok 4\n";

# Duplicate 'filler' should be ok
$parser = Parse::FixedLength->new([
    first_name => '20:1:20',
    filler     => '10:21:30',
    country    =>  '3:31:33',
    filler     => '10R:34:43',
    zip        => '10:44:53',
    filler     => '5:54:58',
], {autonum=>['filler']});

print $not unless $parser;
print "ok 5\n";

# Parse something and check the filler fields
$href = $parser->parse($data);
print $not unless $href
              and $$href{filler_1} eq $ten
              and $$href{filler_2} eq $ten
              and $$href{filler_3} eq $five;
print "ok 6\n";

# 'filler' is ok, but not 'unused'
$parser = eval { Parse::FixedLength->new([
    first_name => '20:1:20',
    filler     => '10:21:30',
    country    =>  '3:31:33',
    filler     => '10R:34:43',
    zip        => '10:44:53',
    unused     => '10:54:63',
    unused     => '10:64:73',
], {autonum=>['filler']})};

print $not unless $@ and $@ =~ /Duplicate field unused/;
print "ok 7\n";
