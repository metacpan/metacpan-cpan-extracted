#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib lib);
use POE qw/Component::WWW::Lipsum/;

my $poco = POE::Component::WWW::Lipsum->spawn;

POE::Session->create( package_states => [ main => [qw/_start lipsum/] ], );

$poe_kernel->run;

sub _start {
    $poco->generate({
            event => 'lipsum',
            args  => {
                amount => 5,
                what   => 'paras',
                start  => 0,
                html   => 1,
            },
        }
    );
}

sub lipsum {
    my $in_ref = $_[ARG0];

    print "$_\n" for @{ $in_ref->{lipsum} };

    $poco->shutdown;
}