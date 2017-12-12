package
    MyUtils;

use strict;
use warnings;

sub new { return bless {}, shift }

sub is_installed {
    my ($obj, %params) = @_;

    my $package = $params{package};

    my %packages_installed = (
        AccountedTimeInOverview => 1,
    );

    return $packages_installed{$package};
}

1;
