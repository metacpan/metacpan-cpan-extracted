#!/usr/bin/env perl 

=pod

Meant to be used within L<Reply>.

Just step into reply, and then do

    $::LOGGING=1; # if you want logging
    do 'examples/reply.pl';

and the Neovim::RPC DSL should be ready to go.

=cut

use strict;
use warnings;

use Neovim::RPC;

our $rpc = Neovim::RPC->new( 
    log_to_stderr => 1 || $::LOGGING,
    debug         => 1
);

$rpc->api->export_dsl;

use Reply;

Reply->new(config => "$ENV{HOME}/.replyrc")->run;
