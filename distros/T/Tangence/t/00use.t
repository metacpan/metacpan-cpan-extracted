#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use_ok( "Tangence" );
use_ok( "Tangence::Class" );
use_ok( "Tangence::Client" );
use_ok( "Tangence::Constants" );
use_ok( "Tangence::Message" );
use_ok( "Tangence::Object" );
use_ok( "Tangence::ObjectProxy" );
use_ok( "Tangence::Property" );
use_ok( "Tangence::Registry" );
use_ok( "Tangence::Server" );
use_ok( "Tangence::Server::Context" );
use_ok( "Tangence::Stream" );

done_testing;
