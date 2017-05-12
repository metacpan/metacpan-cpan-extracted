#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw/Component::WWW::HTMLTagAttributeCounter/;

my $poco = POE::Component::WWW::HTMLTagAttributeCounter->spawn;

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->count( {
            event => 'results',
            where  => 'http://zoffix.com/',
            what   => [ qw/div a span/ ],
        }
    );
}

sub results {
    my $in_ref = $_[ARG0];

    if ( $in_ref->{error} ) {
        print "Error: $in_ref->{error}\n";
    }
    else {
        print "I counted $in_ref->{result_readable} tags on $in_ref->{where}\n";
    }

    $poco->shutdown;
}