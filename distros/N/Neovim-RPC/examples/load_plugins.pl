use 5.20.0;

use strict;
use warnings;

use Test::More;

plan skip_all => 'no nvim listening' unless $ENV{NVIM_LISTEN_ADDRESS};

use Neovim::RPC;
use Promises qw/ deferred /;

use experimental 'signatures';

my $rpc = Neovim::RPC->new;

#use Log::Any::Adapter 'Stderr';

$rpc->on( write => sub { use DDP; p $_[0] } );
$rpc->on( receive => sub { use DDP; p $_[0]->message } );

$rpc->api->ready->then(sub {
    $rpc->load_plugin( 'LoadPlugin');

    $rpc->api->vim_eval( "rpcnotify( nvimx_channel, 'load_plugin', 'FileToPackageName' )" );

    # will lock
    $rpc->api->vim_eval( "rpcrequest( nvimx_channel, 'file_to_package_name' )" );
});


$rpc->run;
