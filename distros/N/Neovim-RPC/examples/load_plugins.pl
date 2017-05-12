use 5.20.0;

use strict;
use warnings;

use Test::More;

plan skip_all => 'no nvim listening' unless $ENV{NVIM_LISTEN_ADDRESS};

use Neovim::RPC;
use Promises qw/ deferred /;

use experimental 'signatures';

my $rpc = Neovim::RPC->new( 
    log_to_stderr => 1, 
);

$rpc->load_plugin( 'LoadPlugin' );

$rpc->api->vim_eval( str => "rpcnotify( nvimx_channel, 'load_plugin', 'FileToPackageName' )" );

$rpc->api->vim_eval( str => "rpcrequest( nvimx_channel, 'file_to_package_name' )" );

my $end_loop = deferred;

$rpc->loop($end_loop);






