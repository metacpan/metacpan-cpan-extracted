#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib lib);
use POE qw(Component::WWW::Alexa::TrafficRank);

@ARGV or die "Usage: perl rank.pl example.com\n";

my $URI = shift;

my $poco = POE::Component::WWW::Alexa::TrafficRank->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start rank )] ],
);

$poe_kernel->run;

sub _start {
    $poco->rank( {
            uri   => $URI,
            event => 'rank',
            _user => 'defined argument',
        }
    );
}

sub rank {
    my $in_ref = $_[ARG0];

    if ( $in_ref->{error} ) {
        print "Error: $in_ref->{error}\n";
    }
    else {
        print "$in_ref->{uri}\'s rank is $in_ref->{rank}\n";
    }
    $poco->shutdown;
}