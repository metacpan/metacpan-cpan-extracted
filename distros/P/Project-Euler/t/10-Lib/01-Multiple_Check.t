use strict;
use warnings;

use Test::More;
use Test::Exception;

use constant LIB => 'Project::Euler::Lib::MultipleCheck';

my @single_tests = (
    [   [1],
        [1, 2, 3, 4, 5, 1000],
        [],
    ],
    [   [2],
        [2, 4, 8324],
        [1, 3, 1241],
    ],
    [   [7],
        [7, 28, 49, 7 ** 11],
        [6, 27, 29, 7 ** 11 - 1],
    ],
);

my %tests = (
    0 => [
        @single_tests,
        [   [2, 3],
            [2, 3, 4, 6, 9, 2*3*234],
            [1, 5, 2*3*3211-1],
        ],
        [   [7, 15],
            [7, 15, 14, 30, 7*15, 7*15*234],
            [1, 6, 16, 7*15+1],
        ],
    ],
    1 => [
        @single_tests,
        [   [2, 3],
            [6, 12, 18, 2*3*42],
            [2, 3, 4, 8, 9],
        ],
        [   [7, 15],
            [7*15, 7*15*23],
            [7, 15, 7*15-1],
        ],
    ],
);

my $sum;
for  my $check_all  (keys %tests) {
    $sum += 1;
    my @checks = @{ $tests{$check_all} };

    for  my $check  (@checks) {
        $sum += 1;

        my ($nums_array, $good, $bad) = @$check;
        $sum += @$good;
        $sum += @$bad;
    }
}
plan tests => 2 + 9 + $sum;

# TESTS 2
use_ok( LIB );
my $problem = new_ok( LIB );

# TESTS 9
ok($problem->multi_nums([1]), 'Error declaring initial multi_nums');
is($problem->check_all(1), 1, 'Error initializing the check_all boolean to 1');
is($problem->check_all(0), 0, 'Error initializing the check_all boolean to 0');
dies_ok {$problem->check(0)} 'The arg to check must be a positive integer, not 0';
dies_ok {$problem->check(-1)} 'The arg to check must be a positive integer, not -1';
dies_ok {$problem->check('test')} 'The arg to check must be a positive integer, not text';
dies_ok {$problem->multi_nums([0])} 'Multi_nums must be an array of positive integers, not [0]';
dies_ok {$problem->multi_nums([-1])} 'Multi_nums must be an array of positive integers, not [-1]';
dies_ok {$problem->multi_nums(['test'])} 'Multi_nums must be an array of positive integers, not ["test"]';


for  my $check_all  (keys %tests) {
    is($problem->check_all($check_all), $check_all, "Error setting the check_all state to $check_all");
    my @checks = @{ $tests{$check_all} };

    for  my $check  (@checks) {
        my ($nums_array, $good, $bad) = @$check;
        my $multi_nums = sprintf('[%s]', join q{, }, @$nums_array);
        ok($problem->multi_nums($nums_array),
           sprintf('Error setting the multi_nums to %s', $multi_nums));
        for  my $ok  (@$good) {
            is($problem->check($ok), 1, "$multi_nums ($check_all) :: $ok not ok");
        }
        for  my $nok  (@$bad) {
            is($problem->check($nok), q{}, "$multi_nums ($check_all) :: $nok ok");
        }
    }
}
