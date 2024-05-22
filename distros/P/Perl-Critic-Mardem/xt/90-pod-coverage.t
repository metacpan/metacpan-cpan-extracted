#!perl

use utf8;

use 5.010;

use strict;
use warnings;

use Cwd        qw( getcwd abs_path );
use Path::This qw( $THISDIR );
use Test::More;
use English qw( -no_match_vars );

if ( !$ENV{ 'TEST_AUTHOR' } ) {
    plan 'skip_all' => 'Author tests not required for installation';
}
else {
    # Ensure a recent version of Test::Pod::Coverage
    my $min_tpc = 1.08;                         ## no critic (ProhibitMagicNumbers)
    local $EVAL_ERROR = undef;
    eval "use Test::Pod::Coverage $min_tpc";    ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    if ( $EVAL_ERROR ) {
        plan 'skip_all' => "Test::Pod::Coverage $min_tpc required for testing POD coverage";
    }

    # Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
    # but older versions don't recognize some common documentation styles
    my $min_pc = 0.18;                   ## no critic (ProhibitMagicNumbers)
    local $EVAL_ERROR = undef;
    eval "use Pod::Coverage $min_pc";    ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    if ( $EVAL_ERROR ) {
        plan 'skip_all' => "Pod::Coverage $min_pc required for testing POD coverage";
    }

    my $cwd_dir      = abs_path( getcwd() );
    my $expected_dir = abs_path( $THISDIR . '/../' );

    chdir $expected_dir;

    all_pod_coverage_ok();

    chdir $cwd_dir;
}

done_testing();

__END__

#-----------------------------------------------------------------------------
