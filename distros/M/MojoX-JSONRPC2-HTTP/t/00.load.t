use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'MojoX::JSONRPC2::HTTP' ) or BAIL_OUT('unable to load module') }

diag( "Testing MojoX::JSONRPC2::HTTP $MojoX::JSONRPC2::HTTP::VERSION, Perl $], $^X" );
