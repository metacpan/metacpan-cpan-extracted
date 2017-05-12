package Pinwheel::Commands::Routes;

use strict;
use warnings;

use Data::Dumper;
use Pinwheel;
use Pinwheel::Controller;

my $routes = $Pinwheel::Controller::map->{routes};

# Pass 1: get the maximum field widths
my $max_name_width = 0;
my $max_route_width = 0;
foreach my $route (@$routes) {
    $max_name_width = length($route->{name}) if $max_name_width < length($route->{name});
    $max_route_width = length($route->{route}) if $max_route_width < length($route->{route});
}

# Pass 2: print out the routing table
foreach my $route (@$routes) {
    printf " %*s %-*s",
       $max_name_width, $route->{name},
       $max_route_width, $route->{route};
    
    my @pairs = ();
    while (my ($key, $value) = each %{$route->{target}})
    {
        push(@pairs,"$key=>'$value'");
    }
    print " {".join(', ',@pairs)."}\n";
}

1;