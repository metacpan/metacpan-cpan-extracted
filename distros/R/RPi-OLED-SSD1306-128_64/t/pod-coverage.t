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

my $pc = Pod::Coverage->new(
    package => 'RPi::OLED::SSD1306::128_64',
    pod_from => 'lib/RPi/OLED/SSD1306/128_64.pm',
    private => [qr/^ssd1306/, qr/^bootstrap$/],
);

is $pc->coverage, 1, "pod coverage ok";

if ($pc->uncovered){
    print "Uncovered:\n\t", join( ", ", $pc->uncovered ), "\n";
}

done_testing;
