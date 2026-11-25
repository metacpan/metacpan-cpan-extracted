#!perl

use 5.036;
use warnings FATAL => q{all};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;
use Test2::API qw{intercept};

use FindBin;
use lib "$FindBin::Bin/lib";

use Cwd        qw{getcwd};
use File::Copy qw{copy};
use File::Temp qw{tempdir};
use List::Util qw{any none};

use Test::Pod::Coverage::More qw{pod_coverage_more_ok all_pod_coverage_more_ok};

# The fixtures, whose POD passes every check, and fails some.
require FullyDocumented;
require Documented;

# Whether each test of an intercepted run passed, and its name.
sub results_of {
    my ($events) = @_;
    my @results;
    foreach my $assert ( @{ $events->asserts } ) {
        push @results, [ $assert->pass ? 1 : 0, $assert->name ];
    }
    return \@results;
}

subtest pod_coverage_more_ok => sub {
    my $passed = intercept { pod_coverage_more_ok('FullyDocumented') };
    is( results_of($passed), [ [ 1, 'POD coverage of FullyDocumented' ] ], "a module whose POD covers everything passes, under the default name" );

    my $failed = intercept { pod_coverage_more_ok( 'Documented', { checks => ['termination'] }, 'only termination' ) };
    is( results_of($failed), [ [ 0, 'only termination' ] ], "a module whose POD misses a termination fails the termination check, under the given name" );
    my @diagnostics = @{ $failed->diag_messages };
    ok( ( any { index( $_, 'Documented: dies_quietly can terminate' ) == 0 } @diagnostics ), "with a diagnostic line for the sub" );
    ok( ( none { index( $_, 'Return type mismatch' ) >= 0 } @diagnostics ),                  "and nothing from the checks that it did not run" );

    my $named = intercept { pod_coverage_more_ok( 'Documented', { checks => [] } ) };
    is( results_of($named), [ [ 1, 'POD coverage of Documented' ] ], "with no checks, it passes when every public sub is documented" );
};

subtest all_pod_coverage_more_ok => sub {
    my $dir = tempdir( CLEANUP => 1 );
    mkdir "$dir/lib"                                                              or die "mkdir: $!";
    copy( "$FindBin::Bin/lib/FullyDocumented.pm", "$dir/lib/FullyDocumented.pm" ) or die "copy: $!";
    my $cwd = getcwd();
    chdir $dir or die "chdir: $!";
    my $events = intercept { all_pod_coverage_more_ok() };
    chdir $cwd or die "chdir: $!";
    is( results_of($events), [ [ 1, 'POD coverage of FullyDocumented' ] ], "one test per module under lib" );
    my ($plan) = map { $_->{plan} } grep { exists $_->{plan} } @{ $events->flatten };
    is( $plan, 1, "planned when nothing planned yet" );
};

done_testing;
