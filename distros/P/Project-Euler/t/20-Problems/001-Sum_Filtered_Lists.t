#!perl -T

use strict;
use warnings;
use autodie;
use List::Util qw/sum/;
use Test::More;


use constant MODULE => 'Project::Euler::Problem::P001';

sub qc {
    my ($nums, $max) = @_;
    my %num_list;

    for  my $num  (@$nums) {
        for (my $i = $num; $i < $max; $i += $num) {
            $num_list{$i} = 1;
        }
    }

    return sum(keys %num_list);
}


my @ok_tests = (
    [
        undef,
        [qw/ 1     0      /],
        [qw/ 3     0      /],
        [qw/ 4     3      /],
        [qw/ 5     3      /],
        [qw/ 6     8      /],
        [qw/ 10    23     /],  # Example given
        [qw/ 1000  233168 /],  # Final solution

        [15, qc([3, 5], 15)],
        [99, qc([3, 5], 99)],
    ],
    [
        [1],
        [1, 0],
        [2, 1],
        [3, 3],
        [4, 6],
        [50,   sum(1.. 49)],
        [100,  sum(1.. 99)],
        [1000, sum(1..999)],
    ],
    [
        [3],
        [qw/ 3 0 /],
        [qw/ 4 3 /],
        [qw/ 7 9 /],
    ],
    [
        [2..5],
        [qw/ 1  0  /],
        [qw/ 2  0  /],
        [qw/ 3  2  /],
        [qw/ 4  5  /],
        [qw/ 5  9  /],
        [qw/ 6  14 /],

        [32, qc([2..5], 32)],
        [77, qc([2..5], 77)],
        [99, qc([2..5], 99)],
    ],
    [
        [7, 9],
        [qw/ 1   0   /],
        [qw/ 7   0   /],
        [qw/ 8   7   /],
        [qw/ 9   7   /],
        [qw/ 10  16  /],

        [63,   qc([7, 9], 63  )],
        [1263, qc([7, 9], 1263)],
    ],
);

my @nok_tests = (
);


my $sum;
for  my $test_array  (grep {scalar @$_ > 0} (\@ok_tests, \@nok_tests)) {
    ($sum += (scalar @$_ - 1) * 1)  for  @$test_array;
}

plan tests => 2 + $sum;

use_ok( MODULE );
diag( 'Checking specific P001 problems' );

my $problem    = new_ok( MODULE );
my $def_multis = $problem->multi_nums();

$problem->use_defaults(0);


for  my $test  (@ok_tests) {
    my $ref = shift @$test;
    my $divs;

    if (ref $ref eq q{}) {
        $problem->multi_nums($def_multis);
        $divs = sprintf('[%s]', join ',', @$def_multis);
    }
    elsif (ref $ref eq q{ARRAY}) {
        $problem->multi_nums($ref);
        $divs = sprintf('[%s]', join ',', @$ref);
    }
    else {
        die "Bad ref type: " . ref $ref;
    }


    for  my $tests  (@$test) {
        my ($in, $out) = @$tests;

        $problem->custom_input($in);
        $problem->custom_answer($out);


        #  Test the module by passing an argument
        my $answer = $problem->solve($in);

        is($out, $answer, sprintf('Arg: Bad return answer for %s => %d -> %d',
                $divs, $in, $out));
    }
}
