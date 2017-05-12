#!perl -T

use strict;
use warnings;

use Test::Most;
use Project::Euler::Lib::Utils qw/ :list /;

my @ok_some = (1, 0,
    [10, [1]],
    [10, [2]],
    [10, [10]],
    [10, [2, 3]],
    [10, [2, 3, 10]],
    [10, [2, 3, 11]],

    # Examples in perlpod
    [15, [2, 3, 5]],
);

my @ok_all = (1, 1,
    [10, [1]],
    [10, [2]],
    [10, [10]],
    [10, [2, 5]],
    [10, [2, 5, 10]],

    #  Examples in perlpod
    [30, [2, 3, 5]],
);

my @nok_some = (0, 0,
    [10, [3]],
    [10, [4]],
    [10, [11]],
    [10, [3, 4]],
    [10, [3, 7]],
    [10, [3, 11]],

    # Examples in perlpod
    [10, [3, 6, 7]]
);

my @nok_all = (0, 1,
    [10, [3]],
    [10, [4]],
    [10, [11]],
    [10, [2, 4]],
    [10, [2, 3]],
    [10, [2, 3, 10]],
    [10, [2, 3, 11]],

    #  Examples in perlpod
    [15, [2, 3, 5]],
);


my @some_return_checks = (0,
    [15, [2, 3, 5], [3, 5]],
    [10, [2, 3, 5], [2, 5]],
    [30, [2, 3, 5], [2, 3, 5]],
    [17, [2, 3, 5], []],
);

my @all_return_checks = (1,
    [15, [2, 3, 5], []],
    [30, [2, 3, 5], [2, 3, 5]],
);


plan tests =>
    @ok_some
  + @ok_all
  + @nok_some
  + @nok_all
  + @some_return_checks
  + @all_return_checks
  - (4*2)  # Minus the type-ints in the arrays
  - (2*1)  # Minus the type-ints in the arrays
;


for  my $test_ref  (\@ok_some, \@ok_all, \@nok_some, \@nok_all) {
    my ($status, $all, @tests) = @$test_ref;

    for  my $test  (@tests) {
        my ($val, $filter_ref) = @$test;
        my $str = sprintf("%d should%s have been filtered by the%s array '%s'",
                            $val,
                            $status ? '' : ' not',
                            $all ? ' entire' : '',
                            join ',', @$filter_ref
                        );

        is( multiple_check( $val, $filter_ref, $all ), $status, $str );
    }
}


for  my $test_ref (\@some_return_checks, \@all_return_checks) {
    my ($all, @tests) = @$test_ref;

    for  my $test  (@tests) {
        my ($val, $filter_ref, $answer_ref) = @$test;
        my $str = sprintf("%d filtered by the%s array '%s' should have returned '%s'",
                            $val,
                            $all ? ' entire' : '',
                            join(',', @$filter_ref),
                            join(',', @$answer_ref),
                        );

        my @filtered_by = multiple_check( $val, $filter_ref, $all );
        cmp_deeply( \@filtered_by, $answer_ref, $str );
    }
}
