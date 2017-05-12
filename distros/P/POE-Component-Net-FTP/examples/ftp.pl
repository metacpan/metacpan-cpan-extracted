#!/usr/bin/env perl;

use strict;
use warnings;
use lib '../lib';
use POE qw(Component::Net::FTP);

die "Usage: perl ftp.pl <host> <login> <password> <file_to_upload>\n"
    unless @ARGV == 4;

my ( $Host, $Login, $Pass, $File ) = @ARGV;

my $poco = POE::Component::Net::FTP->spawn;

POE::Session->create(
    package_states => [ main => [ qw(_start response) ], ],
);

$poe_kernel->run;

sub _start {
    $poco->process( {
            event       => 'response',
            commands    => [
                { new   => [ $Host         ] },
                { login => [ $Login, $Pass ] },
                { put   => [ $File         ] },
            ],
        }
    );
}

sub response {
    my $in_ref = $_[ARG0];

    if ( $in_ref->{is_error} ) {
        print "Failed on $in_ref->{is_error} command: "
                . "$in_ref->{last_error}\n";
    }
    else {
        print "Success!\n";
    }
    $poco->shutdown;
}