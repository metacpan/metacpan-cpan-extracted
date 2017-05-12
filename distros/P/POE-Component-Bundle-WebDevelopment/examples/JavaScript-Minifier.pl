#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);

use POE qw/Component::JavaScript::Minifier/;

my $poco = POE::Component::JavaScript::Minifier->spawn;

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->minify(
        { event => 'results', in => 'var x = 2;' }
    );
}

sub results {
    print "Minified JS:\n$_[ARG0]->{out}\n";
    $poco->shutdown;
}