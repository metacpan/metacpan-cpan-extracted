#!/usr/bin/perl -T
use Test::More tests => 4;

BEGIN {
    use_ok( 'Net::P0f' );
    use_ok( 'Net::P0f::Backend::CmdFE' );
    use_ok( 'Net::P0f::Backend::Socket' );
    use_ok( 'Net::P0f::Backend::XS' );
}

diag( "Testing Net::P0f $Net::P0f::VERSION" );
