use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my $pc = Pod::Coverage->new(
    package => 'RPi::SysInfo',
    pod_from => 'lib/RPi/SysInfo.pm',
    private => [qr/[A-Z]/, qr/^bootstrap$/],
);

is $pc->coverage, 1, "pod coverage ok";

if ($pc->uncovered){
    print "Uncovered:\n\t", join( ", ", $pc->uncovered ), "\n";
}

done_testing();
