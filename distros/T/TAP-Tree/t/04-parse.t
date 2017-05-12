use strict;
use warnings;

use v5.10.1;

use Carp;
use FindBin qw[$Bin];
use File::Spec;

use Test::More tests => 16;

require_ok( 'TAP::Tree' );

subtest '01-success.test' => sub {
    my $tree = execute_test_script( '01-success.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 6;

    is( $plan->{number}, 2, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[0]->{description}, 'first test', 'desc. - first test' );
    is( $testlines->[0]->{test_number}, 1, 'test number - first test' );

    is( $testlines->[1]->{result}, 1, 'result - second test' );

    is( $testlines->[2], undef, 'out of range' );
};

subtest '02-failure.test' => sub {
    my $tree = execute_test_script( '02-failure.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $plan->{number}, 2, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[1]->{result}, 0, 'result - second test' );
};

subtest '03-skip.test' => sub {
    my $tree = execute_test_script( '03-skip.test' );
    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 5;

    is( $plan->{number}, 3, 'number' );

    is( $testlines->[0]->{result}, 1,     'result - first test' );
    is( $testlines->[0]->{skip}, undef,   'is skipped? - first test' );
    is( $testlines->[1]->{result}, 1,     'result - second test' );
    isnt( $testlines->[1]->{skip}, undef, 'is skipped? - second test' );
};

subtest '04-todo.test' => sub {
    my $tree = execute_test_script( '04-todo.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 5;

    is( $plan->{number}, 3, 'number' );

    is( $testlines->[0]->{result}, 1,   'result - first test' );
    is( $testlines->[0]->{todo}, undef, 'is todo? - first test' );
    is( $testlines->[1]->{result}, 0,   'result - second test' );
    isnt( $testlines->[1]->{todo},      'is todo? - second test' );
};

subtest '05-bailout.test' => sub {
    my $tree = execute_test_script( '05-bailout.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    my $bailout   = $tree->{bailout};

    plan tests => 4;

    is( $plan->{number}, 2, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( @{ $testlines }, 1, 'number of taps' );


    is( $bailout->{message}, 'not met the test condition', 'bail out msg' );
};

subtest '06-die.test' => sub {
    my $tree = execute_test_script( '06-die.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    my $bailout   = $tree->{bailout};

    plan tests => 4;

    is( $plan->{number}, 2, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( @{ $testlines }, 1, 'number of taps' );

    is( $bailout->{message}, undef, 'no bailout at die' );
};

subtest '07-donetesting.test' => sub {
    my $tree = execute_test_script( '07-donetesting.test' );

    my $plan      = $tree->{plan};

    plan tests => 1;

    is( $plan->{number}, 2, 'number' );
};

subtest '08-subtest.test' => sub {
    my $tree = execute_test_script( '08-subtest.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 5;

    is( $plan->{number}, 3, 'number' );
    is( @{ $testlines }, 3, 'number of taps' );

    is( $testlines->[0]{description}, 'first test', 'not subtest' );
    is( $testlines->[1]{subtest}{testline}[0]{description},
            'first sub test', 'sub test' );
    is( $testlines->[1]{subtest}{testline}[1]{subtest}{testline}[0]{description}, 'sub sub test', 'sub sub test' );
};

subtest '09-unmatch.test' => sub {
    my $tree = execute_test_script( '09-unmatch.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 2;

    is( $plan->{number}, 3, 'number' );
    is( @{ $testlines }, 2, 'number of taps' );
};

subtest '10-todo_skip.test' => sub {
    my $tree = execute_test_script( '10-todo_skip.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $testlines->[1]->{result}, 0, 'result - second test' );
    ok( $testlines->[1]->{todo}, 'is todo? - second test' );
    ok( $testlines->[1]->{skip}, 'is skipped? - second test' );
};

subtest '11-fail_subtest.test' => sub {
    my $tree = execute_test_script( '11-fail_subtest.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 6;

    is( $plan->{number}, 3, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[1]->{result}, 0, 'result - second test' );

    is( $testlines->[1]{subtest}{testline}[0]{description}, 'first sub test',
            'first sub test' );

    is( $testlines->[1]{subtest}{testline}[0]{result}, 1, 'sub test result' );

    is( $testlines->[1]{subtest}{plan}{number}, 2, 'sub test number' );
};

subtest '12-todo_subtest.test' => sub {
    my $tree = execute_test_script( '12-todo_subtest.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 5;

    is( $plan->{number}, 2, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[1]->{todo}, undef, 'is todo - second test' );

    is( $testlines->[1]{subtest}{testline}[0]{todo}, 1, 'subtest todo' );
    is( $testlines->[1]{subtest}{testline}[0]{result}, 0, 'subtest result' );
};

subtest '13-bailout_subtest_donetesting.test' => sub {
    my $tree = execute_test_script( '13-bailout_subtest_donetesting.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};
    my $bailout   = $tree->{bailout};

    plan tests => 3;

    is( $plan->{number}, undef, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $bailout->{message}, 'bailout!!', 'bail out message' );
};

subtest '14-skipall.test' => sub {
    my $tree = execute_test_script( '14-skipall.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $plan->{number}, 0, 'number' );
    is( $plan->{skip_all}, 1, 'skip' );
    is( $plan->{directive}, 'SKIP skipped all test scripts', 'skip directive' );
};

subtest '15-skipall_aftertest.test' => sub {
    my $tree = execute_test_script( '15-skipall_aftertest.test' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 2;

    is( $plan->{number}, 0, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
};

sub execute_test_script {
    my $test_script = shift;
    my $path  = File::Spec->catfile( $Bin, 'test_stuff', $test_script );

    if ( ! -e $path ) {
        croak "Can't find $path";
    }

    my $tap_output = `$^X $path 2>&1`;
    my $tree = TAP::Tree->new( tap_ref => \$tap_output )->parse;

    return $tree;
}
