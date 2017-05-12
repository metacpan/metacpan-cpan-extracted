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

use RPC::Any::Server::XMLRPC::PSGI;
my $server = RPC::Any::Server::XMLRPC::PSGI->new(
    dispatch  => { 'Foo' => 'My::Module' },
    allow_get => 0,
);
my $handler = sub{ $server->handle_input(@_) };

test_psgi app => $handler, client => sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/', ['Content-Type' => 'text/xml'], 
        '<?xml version="1.0" encoding="utf-8"?><methodCall><methodName>Foo.hello</methodName><params><param><value><string>foo</string></value></param><param><value><string>bar</string></value></param></params></methodCall>'));
    like $res->content, qr/Hello World: foo bar/;
};

done_testing;
