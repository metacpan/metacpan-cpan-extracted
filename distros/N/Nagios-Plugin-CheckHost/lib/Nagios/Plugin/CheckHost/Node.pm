package Nagios::Plugin::CheckHost::Node;

use strict;
use warnings;

sub new {
    my ($class, $id, $location) = @_;
    bless {
        id       => $id,
        country => $location->[0],
        city    => $location->[1],
    }, $class;
}

sub identifier {
    $_[0]->{id}
}

sub city {
    $_[0]->{city}
}

sub country {
    $_[0]->{country}
}

sub shortname {
    sprintf("%s_%s", $_[0]->country, $_[0]->identifier);
}

1;
