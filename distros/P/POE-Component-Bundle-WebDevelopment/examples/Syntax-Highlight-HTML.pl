#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw/Component::Syntax::Highlight::HTML/;

my $poco = POE::Component::Syntax::Highlight::HTML->spawn;

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->parse( {
            event => 'results',
            in    => '<p>Foo <a href="bar">bar</a></p>',
        }
    );
}

sub results {
    print "$_[ARG0]->{out}\n";
    $poco->shutdown;
}