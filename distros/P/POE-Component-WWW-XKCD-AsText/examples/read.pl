#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: perl read.pl <comic_ID>\n"
    unless @ARGV;

my $ID = shift;

use lib '../lib';
use POE qw(Component::WWW::XKCD::AsText);

my $poco = POE::Component::WWW::XKCD::AsText->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start retrieved )] ],
);

$poe_kernel->run;

sub _start {
    $poco->retrieve( {
            id    => $ID,
            event => 'retrieved',
        }
    );
}

sub retrieved {
    my $in = $_[ARG0];

    if ( $in->{error} ) {
        print "Error: $in->{error}\n";
    }
    else {
        printf "The comic on %s is:\n%s\n",
                @$in{ qw(uri text) };
    }

    $poco->shutdown;
}