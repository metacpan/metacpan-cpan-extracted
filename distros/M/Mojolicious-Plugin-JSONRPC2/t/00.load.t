use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Mojolicious::Plugin::JSONRPC2' ) or BAIL_OUT('unable to load module') }

diag( "Testing Mojolicious::Plugin::JSONRPC2 $Mojolicious::Plugin::JSONRPC2::VERSION, Perl $], $^X" );
