#!/usr/bin/perl

use strict;
use POE;
use POE::Component::Server::SimpleXMLRPC;

use Data::Dumper;

POE::Component::Server::SimpleXMLRPC->new(
  PORT => 5555,
  ADDRESS => '127.0.0.1',
  RPC_MAP => {test => sub { return { res => 'test ok:', input => @_, dump => Dumper(@_)} }},
  ALIAS => 'HTTPD',
  RECV_SESSION => 'HTTP_GET',
);

$poe_kernel->run();
