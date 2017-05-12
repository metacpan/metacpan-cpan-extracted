#!/usr/bin/perl 

use strict;
use warnings;


use Neovim::RPC;

Neovim::RPC->new( log_to_stderr => 1 )->api->print_commands;


