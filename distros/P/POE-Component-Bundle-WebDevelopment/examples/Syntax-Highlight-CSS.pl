#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw( lib ../lib );
use POE qw/Component::Syntax::Highlight::CSS/;
my $poco = POE::Component::Syntax::Highlight::CSS->spawn;

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->parse({
            event => 'results',
            in    => 'a:hover { font-weight: bold; }',
            nnn   => 1,
            pre   => 1,
        }
    );
}

sub results {
    print "$_[ARG0]->{out}\n";
    $poco->shutdown;
}