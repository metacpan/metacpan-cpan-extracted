#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Protocol::XMLRPC::Dispatcher;
use Protocol::XMLRPC::MethodCall;

my $dispatcher = Protocol::XMLRPC::Dispatcher->new;

$dispatcher->method(plus => int => [qw/int int/] =>
      'Adds two integers and returns the result' =>
      sub { $_[0]->value + $_[1]->value });

my $method_response;

$dispatcher->dispatch(
    'foo' => sub {
        my $res = shift;

        is($res->fault_string, 'Method call is corrupted');
    }
);

my $req = Protocol::XMLRPC::MethodCall->new(name => 'foo');
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->fault_string, 'Unknown method');
    }
);

$req = Protocol::XMLRPC::MethodCall->new(name => 'plus');
$req->add_param(1);
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->fault_string, 'Wrong prototype');
    }
);

$req = Protocol::XMLRPC::MethodCall->new(name => 'plus');
$req->add_param('foo');
$req->add_param('bar');
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->fault_string, 'Wrong prototype');
    }
);

$req = Protocol::XMLRPC::MethodCall->new(name => 'plus');
$req->add_param(1);
$req->add_param(2);
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->param->value, 3);
    }
);

$req = Protocol::XMLRPC::MethodCall->new(name => 'system.getCapabilities');
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->param->value->{specVersion}, 1);
    }
);

$req = Protocol::XMLRPC::MethodCall->new(name => 'system.listMethods');
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->param->data->[0]->value, 'plus');
    }
);

$req = Protocol::XMLRPC::MethodCall->new(name => 'system.methodSignature');
$req->add_param('plus');
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->param->data->[0]->value, 'int');
        is($res->param->data->[1]->value, 'int');
        is($res->param->data->[2]->value, 'int');
    }
);

$req = Protocol::XMLRPC::MethodCall->new(name => 'system.methodHelp');
$req->add_param('plus');
$dispatcher->dispatch(
    "$req" => sub {
        my $res = shift;

        is($res->param->value, 'Adds two integers and returns the result');
    }
);
