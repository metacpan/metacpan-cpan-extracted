#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

die "Usage: perl support.pl <what_to_lookup>\n"
    unless @ARGV;

my $What = shift;

use lib qw(../lib  lib);
use POE qw(Component::WWW::WebDevout::BrowserSupportInfo);

my $poco = POE::Component::WWW::WebDevout::BrowserSupportInfo->spawn(
    obj_args => { long => 1 },
);

POE::Session->create(
    package_states => [
        main => [ qw(_start fetched) ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->fetch( {
            what  => $What,
            event => 'fetched',
        }
    );
}

sub fetched {
#     use Data::Dumper;
#     print Dumper($_[ARG0]);

    my $in = $_[ARG0];

    print "Support for $in->{what}\n";
    print "\t$_ => ${\(defined $in->{results}{ $_ } ? $in->{results}{ $_ } : '')}\n"
        for keys %{ $in->{results} };

    print "For more information visit: $in->{uri_info}\n";

    $poco->shutdown;
}

