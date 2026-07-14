#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use POE qw(Component::WWW::OhNoRobotCom::Search);

die "Usage: perl search.pl <term_to_search_XKCD_comics_for>\n"
    unless @ARGV;

my $Term = shift;

my $poco = POE::Component::WWW::OhNoRobotCom::Search->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start results )] ],
);

$poe_kernel->run;

sub _start {
    $poco->search( {
            term     => $Term,
            comic_id => 56,
            event    => 'results',
        }
    );
}

sub results {
    my $in_ref = $_[ARG0];

    exists $in_ref->{error}
        and die "ZOMG! ERROR!: $in_ref->{error}";

    print "Results for XKCD comic search are as follows:\n";

    keys %{ $in_ref->{results} };
    while ( my ( $uri, $title ) = each %{ $in_ref->{results} } ) {
        print "$title [ $uri ]\n";
    }

    $poco->shutdown;
}
