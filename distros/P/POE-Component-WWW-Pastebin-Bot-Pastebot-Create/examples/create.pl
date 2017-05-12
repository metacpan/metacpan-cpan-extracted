#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib  lib);
use POE qw(Component::WWW::Pastebin::Bot::Pastebot::Create);

my $poco = POE::Component::WWW::Pastebin::Bot::Pastebot::Create->spawn;

POE::Session->create(
    package_states => [ main => [ qw(_start pasted) ], ],
);

$poe_kernel->run;

sub _start {
    $poco->paste( {
            event       => 'pasted',
            content     => 'test',
            summary     => 'just testing',
            nick        => 'foos',
        }
    );
}

sub pasted {
    my $in_ref = $_[ARG0];

    if ( $in_ref->{error} ) {
        print "Got error: $in_ref->{error}\n";
    }
    else {
        print "Your paste is located on $in_ref->{uri}\n";
    }
    $poco->shutdown;
}