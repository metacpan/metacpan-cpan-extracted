#!perl

use utf8;

use 5.010;

use strict;
use warnings;

use Cwd        qw( abs_path );
use Path::This qw( $THISDIR );
use Test::More;
use English qw( -no_match_vars );

if ( !$ENV{ 'TEST_AUTHOR' } ) {
    plan 'skip_all' => 'Author tests not required for installation';
}
else {
    # Ensure a recent version of Test::Pod
    my $min_tp = 1.22;               ## no critic (ProhibitMagicNumbers)
    eval "use Test::Pod $min_tp";    ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    if ( $EVAL_ERROR ) {
        plan 'skip_all' => "Test::Pod $min_tp required for testing POD";
    }

    my @poddirs = ( abs_path( $THISDIR ) . '/../' );

    all_pod_files_ok( all_pod_files( @poddirs ) );
}

done_testing();

__END__

#-----------------------------------------------------------------------------
