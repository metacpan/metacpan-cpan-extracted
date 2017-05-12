#!/usr/bin/perl
use strict;
use warnings;

use LWP::Simple;

my $uri_base  = 'http://api.hope.net/api/';
my $file_base = './t/data/';

my @paths = (
    'interests', 'location', 'speakers', 'stats', 
    'talks', 'users', 'location?user=user0',
);


foreach my $path (@paths) {
    my $uri  = $uri_base  . $path;

    $path =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    my $file = $file_base . $path;
    
    print "mirror( $uri, $file )\n";

    my $response = mirror( $uri, $file );
    if (!is_success( $response )) {
        print "\tError: $response\n";
    }
}
