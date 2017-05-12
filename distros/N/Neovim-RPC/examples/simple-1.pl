#!/usr/bin/perl 

use 5.10.0;

use strict;
use warnings;

use Neovim::RPC;

my $rpc = Neovim::RPC->new(
    log_to_stderr => 1,
    #debug => 1,
);

# TODO different example, and use the interface to have neovim send the
# command
0 and $rpc->subscribe( 'potato' => sub {
    my $event = shift;
    say $event->all_args;
});

$rpc->api->vim_set_current_line( line => "victory!" )
    ->then( sub {
        my( $response ) = @_;
        $rpc->api->vim_set_current_line( line => 'even better!' );
    });

$rpc->loop;
