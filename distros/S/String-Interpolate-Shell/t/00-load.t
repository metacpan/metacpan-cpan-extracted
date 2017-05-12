#!/proj/axaf/ots/pkgs/perl-5.12/x86_64-linux_debian-5.0/bin/perl -w

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { 
    use_ok( 'String::Interpolate::Shell' );
}



diag( "Testing String::Interpolate::Shell $String::Interpolate::Shell::VERSION, Perl $], $^X" );

