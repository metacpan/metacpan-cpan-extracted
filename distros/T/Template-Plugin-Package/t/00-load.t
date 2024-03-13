#!perl

use 5.010;
use warnings;
use strict;

use Test::More tests => 1;

use Template::Plugin::Package;

MAIN: {
    pass( 'Module loaded' );

    diag sprintf( 'Testing Template::Plugin::Package %s under Perl v%vd, %s', $Template::Plugin::Package::VERSION, $^V, $^X );
}


exit 0;
