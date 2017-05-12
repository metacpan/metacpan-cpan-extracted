use strict;
use warnings;

use Test::More tests => 4;

require TAP::Tree;

subtest 'pass' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
ok 2 - second test
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    plan tests => 7;

    is( $summary->{is_skipped_all}, 0, 'is skipped all' );
    is( $summary->{is_bailout},     0, 'is bail out' );
    is( $summary->{planned_tests},  2, 'planned tests' );
    is( $summary->{ran_tests},      2, 'ran tests' );
    is( $summary->{failed_tests},   0, 'failed tests' );

    is( $summary->{is_good_plan},   1, 'is good plan' );
    is( $summary->{is_ran_all_tests}, 1, 'is ran all tests' );
};

subtest 'fail' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
not ok 2 - second test
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    plan tests => 7;

    is( $summary->{is_skipped_all}, 0, 'is skipped all' );
    is( $summary->{is_bailout},     0, 'is bail out' );
    is( $summary->{planned_tests},  2, 'planned tests' );
    is( $summary->{ran_tests},      2, 'ran tests' );
    is( $summary->{failed_tests},   1, 'failed tests' );

    is( $summary->{is_good_plan},   1, 'is good plan' );
    is( $summary->{is_ran_all_tests}, 1, 'is ran all tests' );
};

subtest 'bailout' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
Bail out!  stop test!
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    plan tests => 8;

    is( $summary->{is_skipped_all}, 0, 'is skipped all' );
    is( $summary->{is_bailout},     1, 'is bail out' );
    is( $summary->{bailout_msg},    'stop test!' , 'bail out msg' );
    is( $summary->{planned_tests},  2, 'planned tests' );
    is( $summary->{ran_tests},      1, 'ran tests' );
    is( $summary->{failed_tests},   0, 'failed tests' );

    is( $summary->{is_good_plan},   1, 'is good plan' );
    is( $summary->{is_ran_all_tests}, 0, 'is ran all tests' );
};

subtest 'todo' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
not ok 2 - second test # TODO
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    plan tests => 7;

    is( $summary->{is_skipped_all}, 0, 'is skipped all' );
    is( $summary->{is_bailout},     0, 'is bail out' );
    is( $summary->{planned_tests},  2, 'planned tests' );
    is( $summary->{ran_tests},      2, 'ran tests' );
    is( $summary->{failed_tests},   0, 'failed tests' );

    is( $summary->{is_good_plan},   1, 'is good plan' );
    is( $summary->{is_ran_all_tests}, 1, 'is ran all tests' );
};

