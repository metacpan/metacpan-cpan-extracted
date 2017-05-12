#!/usr/bin/perl 

use 5.10.0;

use strict;
use warnings;

use Neovim::RPC;

my $rpc = Neovim::RPC->new(
    log_to_stderr => 1,
    #debug => 1,
);

my $id = $rpc->api->channel_id;

say "we are at $id";

$rpc->api->vim_command( str => "let nvimx_channel = $id" );

$rpc->loop;
