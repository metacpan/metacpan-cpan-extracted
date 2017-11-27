#!/usr/bin/perl 

use strict;
use warnings;

use Neovim::RPC;

use Log::Any::Adapter 'Stderr';

my $client = Neovim::RPC->new( io => '/tmp/nvimd9VEXB/0' );

    $client->on( 'receive', sub { use DDP; p $_[0] } );
   $client->on( 'write', sub { use DDP; p $_[0]->message } );

$client->api->ready
    ->then(sub{ $_[0]->print_commands; $_[0] })
    ->then(sub{ $_[0]->rpc->loop->stop });

$client->run;




