#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib ../lib);

@ARGV
    or die "Usage: perl $0 'Location for the time #1' 'Location #2' Location_3\n";

use POE qw/Component::WWW::Google::Time/;
my $poco = POE::Component::WWW::Google::Time->spawn;

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->get_time({ event => 'results', where => $_ })
        for @ARGV;
}

sub results {
    my $data = $_[ARG0];

    if ( $data->{error} ) {
        print "Error: $data->{error}\n";
    }
    else {
        printf "It is %s, %s (%s) in %s\n",
            @{ $data->{result} }{ qw/day_of_week  time  time_zone  where/ };
    }
    $poco->shutdown;
}