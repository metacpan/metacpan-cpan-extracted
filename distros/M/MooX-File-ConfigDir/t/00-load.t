#!perl -T

use strict;
use warnings FATAL => "all";

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooX::File::ConfigDir' ) || BAIL_OUT "Couldn't load MooX::File::ConfigDir";
}

diag( "Testing MooX::File::ConfigDir $MooX::File::ConfigDir::VERSION, Perl $], $^X" );
