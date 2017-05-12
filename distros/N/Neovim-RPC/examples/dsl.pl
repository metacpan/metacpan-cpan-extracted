#!/usr/bin/perl 

use strict;
use warnings;

package Potato;

use Neovim::RPC;

my $rpc  = Neovim::RPC->new( log_to_stderr => 1, debug => 0 );

$rpc->api->export_dsl;

vim_set_current_line( 'victory' );
