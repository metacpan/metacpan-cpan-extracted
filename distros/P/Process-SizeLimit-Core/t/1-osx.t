#! /usr/bin/env perl

BEGIN {
    # fake loading of Config module
    $INC{Config} = 1;
    %Config::Config = ( 
        osname => 'darwin'
    );
}

use strict;
use warnings;
use Test::More;

# Ensure module can be used on OSX
ok( !$INC{'BSD/Resource.pm'}, 'BSD::Resource not loaded yet' );
SKIP: {
    skip 'Not on OSX', 1 unless $^O eq 'darwin';
    use_ok('Process::SizeLimit::Core');
    ok( $INC{'BSD/Resource.pm'}, 'BSD::Resource loaded on OSX' );
}
done_testing;
