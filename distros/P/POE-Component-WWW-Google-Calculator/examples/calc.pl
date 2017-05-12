#!perl

use strict;
use warnings;

use lib qw(../lib  lib);
die "Usage: perl calc.pl 'term to calculate'\n"
    unless @ARGV;

my $Term = shift;


use POE qw(Component::WWW::Google::Calculator);

my $poco = POE::Component::WWW::Google::Calculator->spawn;

POE::Session->create(
    package_states => [
        main => [ qw(_start calc) ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->calc( { event => 'calc', term => $Term } );
}

sub calc {
    my $result = $_[ARG0];
    if ( $result->{error} ) {
        print "Error: $result->{error}\n";
    }
    else {
        print "Result: $result->{out}\n";
    }
    $poco->shutdown;
}

