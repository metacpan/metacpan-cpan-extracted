package My::Module;

use strict;

sub hello {
    my $self = shift;
    return "Hello World: @_";
}

package main;

use strict;
use Test::More;
use Plack::Test;

use RPC::Any::Server::JSONRPC::PSGI;
my $server = RPC::Any::Server::JSONRPC::PSGI->new(
    dispatch  => { 'Foo' => 'My::Module' },
    allow_get => 0,
);
my $handler = sub{ $server->handle_input(@_) };

test_psgi app => $handler, client => sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/', ['Accept' => 'application/json-rpc', 'Content-Type' => 'application/json-rpc'], 
                                       '{"jsonrpc": "2.0", "method": "Foo.hello", "params": ["foo", "bar"], "id": 1}'));
    like $res->content, qr/Hello World: foo bar/;
};

done_testing;
