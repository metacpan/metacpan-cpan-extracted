# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::FixedLength;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
my $not = 'not ';

my $parser1 = Parse::FixedLength->new([qw(
    first_name:10
    last_name:10
    widgets_this_month:5R
    zip:5
    zip_plus_4:4
)]);

print $not unless defined $parser1;
print "ok 2\n";

my $parser2 = Parse::FixedLength->new([
    seq_id     => '10:1:10',
    first_name => '10:11:20',
    last_name  => '10:21:30',
    country    =>  '3:31:33',
    widgets_this_year => '10R:34:43',
    zip => '10:44:53',
]);

print $not unless defined $parser2;
print "ok 3\n";

my $converter = $parser1->converter($parser2, {
    widgets_this_month => widgets_this_year,
},{
    seq_id => do { my $cnt = '0' x $parser2->length('seq_id');
                   sub { ++$cnt };
                 },
    country => 'USA',
    widgets_this_year => sub { 12 * shift },
    zip => sub { shift()."-".$_[0]{zip_plus_4} },
});

print $not unless defined $converter;
print "ok 4\n";

my $str_in = 'BOB       JONES        24999990000';
my $str_out = $converter->convert($str_in);
print $not unless $str_out eq '0000000001BOB       JONES     USA       28899999-0000';
print "ok 5\n";
