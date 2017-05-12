#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(Component::WWW::DoctypeGrabber);

@ARGV
    or die "Usage: perl $0 page1 page2 .. pageN\n";

my $poco = POE::Component::WWW::DoctypeGrabber->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start results)] ],
);

$poe_kernel->run;

sub _start {
    $poco->grab( {
            page  => $_,
            event => 'results',
        }
    ) for @ARGV;
}

sub results {
    my $in_ref = $_[ARG0];

    if ( $in_ref->{error} ) {
        print "ERROR: $in_ref->{error}\n";
    }
    else {
        my $result = $in_ref->{result};

        print $result->{has_doctype}
            ? "$in_ref->{page} has $result->{doctype} doctype\n"
            : "$in_ref->{page} does not contain a doctype\n";

        print $result->{xml_prolog}
            ? "Contains XML prolog\n" : "Does not contain XML prolog\n";

        print "Doctype is preceeded by $result->{non_white_space} non-whitespace characters\n";
        print "\n\n\n";
    };

    $poco->shutdown;
}