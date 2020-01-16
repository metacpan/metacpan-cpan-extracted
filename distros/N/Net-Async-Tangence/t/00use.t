#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Net::Async::Tangence::Protocol" );
use_ok( "Net::Async::Tangence::ServerProtocol" );
use_ok( "Net::Async::Tangence::Client" );
use_ok( "Net::Async::Tangence::Server" );

use_ok( "Net::Async::Tangence::Client::via::$_" ) for
   qw( sshexec sshunix );

done_testing;
