#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);

use POE qw(Component::WWW::GetPageTitle);

@ARGV
    or die "Usage: perl $0 page1 page2 ... pageN\n";

my $poco = POE::Component::WWW::GetPageTitle->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start result )] ],
);

$poe_kernel->run;

sub _start {
    $poco->get_title( {
            page  => $_,
            event => 'result',
        }
    ) for @ARGV;
}

sub result {
    my $in_ref = $_[ARG0];

    if ( $in_ref->{error} ) {
        print "ERROR: $in_ref->{error}\n";
    }
    else {
        print "Title of $in_ref->{page} is $in_ref->{title}\n";
    }

    $poco->shutdown;
}
