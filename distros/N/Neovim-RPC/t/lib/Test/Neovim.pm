package Test::Neovim;

use strict;
use warnings;

use Test::More;
use Net::EmptyPort;
use Neovim::RPC;

use Exporter;

use parent 'Exporter';

our @EXPORT_OK = ( '$rpc' );

my $diag = `nvim -v` or
    plan skip_all => "can't run nvim";

unless( $ENV{NVIM_LISTEN_ADDRESS} ) {
    diag "NVIM_LISTEN_ADDRESS: " 
        . ( $ENV{NVIM_LISTEN_ADDRESS} = '127.0.0.1:'.empty_port() );

    exec 'nvim', '--headless' unless fork;

    sleep 1;
}


our $rpc = Neovim::RPC->new( 
    log_to_stderr => 0, debug => 0,
);

1;
