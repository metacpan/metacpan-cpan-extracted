use strict;
use warnings;

use Test::More 0.88;

use File::Copy::Recursive qw( dircopy );
use File::chdir;
use Test::DependentModules ();
use IPC::Run3 qw( run3 );

for my $builder (qw( eumm mb mbt )) {
    my ( $success, $out, $err ) = test_corpus("no_tests_$builder");
    ok $success, "considered passing with no tests using $builder"
        or diag "Output:\n$out\nError:\n$err";

    ( $success, $out, $err ) = test_corpus("skipped_tests_$builder");
    ok $success, "considered passing with all tests skipped using $builder"
        or diag "Output:\n$out\nError:\n$err";
}

{
    my ( $success, $out, $err ) = test_corpus('broken_passing');
    ok(
        !$success,
        'considered failing even when output contains random Result: PASS'
    ) or diag "Output:\n$out\nError:\n$err";
}

done_testing();

sub test_corpus {
    my $dist = shift;

    my $temp_dir = File::Temp::tempdir( CLEANUP => 1 );
    dircopy( "corpus/$dist", $temp_dir );

    local $CWD = $temp_dir;

    my ( $stdout, $stderr );
    run3(
        [
            $^X,
            ( -e 'Build.PL' ? 'Build.PL' : 'Makefile.PL' )
        ],
        \undef,
        \$stdout,
        \$stderr,
    );

    if ( $? != 0 ) {
        die "Can't build $dist:\nOutput:\n$stdout\nError:\n$stderr\n";
    }

    ## no critic (Subroutines::ProtectPrivateSubs)
    return Test::DependentModules::_run_tests_for_dir($temp_dir);
}
