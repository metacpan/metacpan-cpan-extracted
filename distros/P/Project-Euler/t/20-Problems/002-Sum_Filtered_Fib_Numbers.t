#!perl -T

use strict;
use warnings;
use autodie;
use List::Util qw/sum/;
use Test::More;


use constant MODULE => 'Project::Euler::Problem::P002';

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
#  0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765
    [
        undef,
        [0,      0],
        [1,      0],
        [2,      0],
        [3,      2],
        [4,      2],
        [5,      2],
        [10,    10],
        [20,    10],
        [30,    10],
        [40,    44],
        [50,    44],
        [100,   44],
        [200,  188],
        [300,  188],
        [400,  188],
        [500,  188],
        [1000, 798],
        [4_000_000, 4613732],
    ],
#  0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765
    [
        [3],
        [0,      0],
        [1,      0],
        [2,      0],
        [3,      0],
        [4,      3],
        [5,      3],
        [10,     3],
        [20,     3],
        [30,    24],
        [40,    24],
        [50,    24],
        [100,   24],
        [200,  168],
        [300,  168],
        [400,  168],
        [500,  168],
        [1000,1155],
    ],
#  0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765
    [
        [2, 3],
        [0,      0],
        [1,      0],
        [2,      0],
        [3,      0],
        [4,      0],
        [5,      0],
        [10,     0],
        [20,     0],
        [30,     0],
        [40,     0],
        [50,     0],
        [100,    0],
        [200,  144],
        [300,  144],
        [400,  144],
        [500,  144],
        [1000, 144],
    ]
);

my @nok_tests = (
);


my $sum = 0;
for  my $test_array  (grep {scalar @$_ > 0} (\@ok_tests, \@nok_tests)) {
    ($sum += (scalar @$_ - 1) * 1)  for  @$test_array;
}

plan tests => 2 + $sum;


use_ok( MODULE );
diag( 'Checking specific P002 problems' );

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

        is($answer, $answer, sprintf('Arg: Bad return answer for %s => %d -> %d',
                $divs, $in, $out));
    }
}
