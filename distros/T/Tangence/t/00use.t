#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Tangence;
require Tangence::Class;
require Tangence::Client;
require Tangence::Constants;
require Tangence::Message;
require Tangence::Object;
require Tangence::ObjectProxy;
require Tangence::Property;
require Tangence::Registry;
require Tangence::Server;
require Tangence::Server::Context;
require Tangence::Stream;

pass( 'Modules loaded' );
done_testing;
