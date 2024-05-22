#!perl

use utf8;

use 5.010;

use strict;
use warnings;

use Test::More;
use English qw( -no_match_vars );

if ( !$ENV{ 'RELEASE_TESTING' } && !$ENV{ 'TEST_AUTHOR' } ) {
    plan 'skip_all' => 'Release and Author tests not required for installation';
}
else {
    my $min_tcm = 0.9;                          ## no critic (ProhibitMagicNumbers)
    eval "use Test::CheckManifest $min_tcm";    ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    if ( $EVAL_ERROR ) {
        plan 'skip_all' => "Test::CheckManifest $min_tcm required";
    }

    ok_manifest( { 'filter' => [ qr/ignore[.]txt/ixmso, qr/[.]gitignore/ixmso ] } );
}

done_testing();

__END__

#-----------------------------------------------------------------------------
