#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib lib);

use POE qw(Component::WWW::Cache::Google);

@ARGV or die "Usage: perl cache.pl http://example.com/\n";

my $URI = shift;

my $poco = POE::Component::WWW::Cache::Google->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start cache)] ],
);

$poe_kernel->run;

sub _start {
    $poco->cache( {
            uri   => $URI,
            event => 'cache',
            fetch => 1,
            overwrite => 1,
        }
    );
}

sub cache {
    my $in_ref = $_[ARG0];

    print "Cache URI for $in_ref->{uri} is: $in_ref->{cache}\n";
    if ( $in_ref->{error} ) {
        print "Got error fetching it: $in_ref->{error}\n";
    }
    else {
        print "Content:\n$in_ref->{content}\n";
    }

    $poco->shutdown;
}