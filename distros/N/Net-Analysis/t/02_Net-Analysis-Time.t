# $ cd Net::Analysis
# $ make test                        # Run all test files
# $ PERL5LIB=./lib perl t/00_stub.t  # Run just this test suite

# $Id: 02_Net-Analysis-Time.t 143 2005-11-03 17:36:58Z abworrall $

use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 24;

#########################

BEGIN { use_ok('Net::Analysis::Time') };

# Simple construction
my $t1 = Net::Analysis::Time->new (1100257189, 123456);
isnt ($t1, undef, 'create obj');

# getting the bits back
is_deeply (scalar($t1->numbers()), [1100257189, 123456], 'get bits back');

# Test the pre-packaged output formats
Net::Analysis::Time->set_format ('full');
is ("$t1", '2004/11/12 10:59:49.123456', 'fulloutput');
Net::Analysis::Time->set_format ('time');
is ("$t1", '10:59:49.123456', 'time output');
Net::Analysis::Time->set_format ('raw');
is ("$t1", '1100257189.123456', 'raw output');

# Test format overrides
is ($t1->as_string('time'), '10:59:49.123456', 'time override');
is ("$t1", '1100257189.123456', 'time back to normal');

# Additions
$t1 += 0.000001;
is ("$t1", '1100257189.123457', '+NN');

$t1 += [2,999999]; # (test rollovers)
is ("$t1", '1100257192.123456', '+[s,us]');

$t1 += Net::Analysis::Time->new (3, 111111);
is ("$t1", '1100257195.234567', '+$t');

# Subtractions
$t1 -= 0.000001;
is ("$t1", '1100257195.234566', '-NN');

$t1 -= [2,999999]; # (test rollunders)
is ("$t1", '1100257192.234567', '-[s,us]');

$t1 -= Net::Analysis::Time->new (3, 111111);
is ("$t1", '1100257189.123456', '-$t');

# Comparisons
my $t2 = Net::Analysis::Time->new (1100257189, 123456);
cmp_ok ($t1, '==', $t2, '==');

$t2 += [0,000001];
cmp_ok ($t1, '!=', $t2, '!=');

# Cloning
my $t3 = $t1->clone();
cmp_ok ($t1, '==', $t3, 'clone is OK');

$t2 -= [6,000000];
my $diff = $t1 - $t2;
my $sum  = $t1 + [100,111111];
cmp_ok ($diff, '==', Net::Analysis::Time->new(5,999999),          'subtraction');
cmp_ok ($sum,  '==', Net::Analysis::Time->new(1100257289,234567), 'addition');

# Rounding
$t1->round_usec(10);
is ("$t1", '1100257189.123450', 'round 10');

$t1->round_usec(250,'up');
is ("$t1", '1100257189.123500', 'round 250, up');

$t1->round_usec(5000);
is ("$t1", '1100257189.120000', 'round 5000');

$t1->round_usec(1000000,'up');
is ("$t1", '1100257190.000000', 'round 1000000, up');

# Other stuff
is ($diff->usec(), 5999999, 'usec()');

__DATA__
# ok        ($this eq $that,     $test_name);
# is        ($this,   $that,     $test_name);
# isnt      ($this,   $that,     $test_name);
# diag      ("blah blah");
# like      ($this,   qr/that/,  $test_name);
# unlike    ($this,   qr/that/,  $test_name);
# cmp_ok    ($this, '==', $that, $test_name);
# is_deeply (\@output, \@sample_answers, "something");
