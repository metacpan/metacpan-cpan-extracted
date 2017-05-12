#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use POE qw(Component::WWW::Pastebin::Many::Retrieve);

my $poco = POE::Component::WWW::Pastebin::Many::Retrieve->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start retrieved)] ],
);

$poe_kernel->run;

sub _start {
    $poco->retrieve( {
            uri     => 'http://phpfi.com/302683',
            event   => 'retrieved',
            _random => scalar localtime,
        }
    );
}

sub retrieved {
    my $in_ref = $_[ARG0];

    print "This is request from $in_ref->{_random}\n";

    if ( $in_ref->{error} ) {
        print "Got error: $in_ref->{error}\n";
    }
    else {
        print "Paste $in_ref->{uri} contains:\n$in_ref->{content}\n";
    }

    $poco->shutdown;
}
