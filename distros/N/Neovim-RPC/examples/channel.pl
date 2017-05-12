#!/usr/bin/perl 

use 5.10.0;

use strict;
use warnings;

use Neovim::RPC;

my $rpc = Neovim::RPC->new(
    log_to_stderr => 1,
    #debug => 1,
);

say "my channel is ", $rpc->api->channel_id;

$rpc->subscribe( 'doit' => sub {
    my $event = shift;
    $event->emitter->api->vim_get_current_line
        ->on_done(sub{
            $event->reply( scalar reverse shift );
        });
});

$rpc->loop;
