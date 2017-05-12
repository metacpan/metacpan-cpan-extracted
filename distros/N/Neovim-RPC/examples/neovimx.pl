#!/usr/bin/env perl 

use strict;
use warnings;

use  Neovim::RPC;

my $rpc = Neovim::RPC->new;

$rpc->load_plugin('LoadPlugin');

$rpc->loop;

