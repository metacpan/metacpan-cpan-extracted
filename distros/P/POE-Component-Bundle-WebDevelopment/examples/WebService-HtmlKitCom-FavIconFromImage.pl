#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib ../lib};
use POE qw(Component::WebService::HtmlKitCom::FavIconFromImage);

die "Usage: perl fav.pl <file_name_of_picture_to_make_favicon_from>\n"
    unless @ARGV;

my $Image = shift;

my $poco = POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn;

POE::Session->create(
    package_states => [ main => [qw(_start result)] ],
);

$poe_kernel->run;

sub _start {
    $poco->favicon( {
            image => $Image,
            file  => 'out.zip',
            event => 'result',
        }
    );
}

sub result {
    my $in_ref = $_[ARG0];

    if ( exists $in_ref->{error} ) {
        print "Got error: $in_ref->{error}\n";
    }
    else {
        print "Done! I saved your favicon in out.zip file\n";
    }

    $poco->shutdown;
}