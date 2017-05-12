#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 2;

require_ok('POE::Component::Server::HTTP::KeepAlive');
require_ok('POE::Component::Server::HTTP::KeepAlive::SimpleHTTP');
