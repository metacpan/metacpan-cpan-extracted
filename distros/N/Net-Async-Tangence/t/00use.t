#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Net::Async::Tangence::Protocol" );
use_ok( "Net::Async::Tangence::ServerProtocol" );
use_ok( "Net::Async::Tangence::Client" );
use_ok( "Net::Async::Tangence::Server" );

done_testing;
