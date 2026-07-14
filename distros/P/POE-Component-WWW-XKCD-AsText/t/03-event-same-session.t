#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

my $ID=1;

use POE qw(Component::WWW::XKCD::AsText);

POE::Component::WWW::XKCD::AsText->spawn(debug=>1, alias => 'xkcd');

POE::Session->create(
    package_states => [ main => [qw(_start ret) ] ]
);

$poe_kernel->run;

sub _start {
    $poe_kernel->post( xkcd => retrieve => {
            id => $ID,
            event => 'ret',
            _user => 'foos',
        },
    );
}

sub ret {
    my $in = $_[ARG0];
    is(
        ref $in,
        'HASH',
        '$_[ARG0] must contain a hashref',
    );
    SKIP: {
        if ( $in->{error} ) {
            diag "Got error $in->{error}";
            ok( (defined $in->{error} and length $in->{error}),  '{error}');
            is( $in->{id}, $ID, '{id} must have id on error');
            is( $in->{_user}, 'foos', '{_user} must have user argument');
            is( scalar keys %$in, 3, '$_[ARG0] must have only three keys');
        }
        else {
            isa_ok($in->{uri}, 'URI::http');
            is(
                $in->{uri},
                "http://xkcd.com/1/",
                '{uri} must be pointing to the right comic'
            );
            my $VAR1 = "[[A boy sits in a barrel which is floating in an ocean.]]\r\n\r\nBoy: I wonder where I'll float next?\r\n\r\n[[The barrel drifts into the distance. Nothing else can be seen.]]\r\n\r\n{{Alt: Don't we all.}}";
            is(
                $in->{text},
                $VAR1,
                'text must match the dump',
            );
            skip "No errors, skipping ERROR tests", 1;
        }
    } # SKIP{}
    $poe_kernel->post( xkcd => 'shutdown' );
}