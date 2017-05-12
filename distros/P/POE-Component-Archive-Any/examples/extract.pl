#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use POE qw(Component::Archive::Any);

die "Usage: perl extract.pl <archive_filename_to_extract>\n"
    unless @ARGV;

my $Archive_to_extract = shift;

my $poco = POE::Component::Archive::Any->spawn(debug=>1);

POE::Session->create(
    package_states => [
        main => [ qw( _start  extracted ) ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->extract( {
            event => 'extracted',
            file  => $Archive_to_extract,
        }
    );
}

sub extracted {
    my $in = $_[ARG0];

    if ( $in->{error} ) {
        print "Error: $in->{error}\n";
    }
    else {
        print "The archive extracts itself to outside directory\n"
            if $in->{is_naughty};
        print "The archive extracts itself to the current directory\n"
            if $in->{is_impolite};

        print "Extracted $in->{file} archive which is of type "
                . "$in->{type} and contains the following files:\n";

        print "$_\n" for @{ $in->{files} };
    }
    $poco->shutdown;
}

