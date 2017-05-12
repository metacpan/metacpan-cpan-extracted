#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;

use IO::Pipe;
use lib 't/lib';

use_ok('RPC::Serialized::Server');
use_ok('RPC::Serialized::Client');

my $server_in  = IO::Pipe->new() or die "Failed to create input pipe: $!";
my $server_out = IO::Pipe->new() or die "Failed to create output pipe: $!";

my $pid = fork();
defined $pid or die "Fork failed: $!";
if ( $pid == 0 ) {    # child
    # FIXME would be nice to test the log suppression but with the syslog
    # logger this needs something like Sys::Syslog t/data-validation.t

    $server_in->reader();
    $server_out->writer();
    my $s = RPC::Serialized::Server->new({
        rpc_serialized => {ifh => $server_in, ofh => $server_out,
        handler_namespaces => ['RPC::Serialized::Handler', 'Handlers']},
    });
    $s->process();
    exit 0;
}

# Block introduced to test that server sees eof and terminates process() loop
# when client goes out of scope
{
    $server_in->writer();
    $server_out->reader();
    my $c = RPC::Serialized::Client->new({
        rpc_serialized => {ifh => $server_out, ofh => $server_in}
    });
    isa_ok( $c, 'RPC::Serialized::Client' );

    my @args = qw(a b c d);
    my $res = eval { $c->echo(@args) };
    ok( ! $@, "Died in rpc call: $@" );
    ok( eq_array( $res, \@args ) );

    @args = ( 1, 2, 3, 4, 'a', 'b', 'c', 'd' );
    $res = eval { $c->echo(@args) };
    ok( ! $@ );
    ok( eq_array( $res, \@args ) );

    eval { $c->foo( 1, 2, 3 ) };
    isa_ok( $@, 'RPC::Serialized::X::Application' );
    is( $@->message, 'No handler for foo' );

    $res = eval { $c->suppress( this => 'that', foo => 'bar' ) };
    ok( ! $@ );
    is( $res, 4 );
}

is( waitpid( $pid, 0 ), $pid );
my $r = ($? == 512 ? 512 : 0);
is( $?, $r );
