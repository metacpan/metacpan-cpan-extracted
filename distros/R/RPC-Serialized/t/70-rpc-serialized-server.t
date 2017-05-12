#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/70-rpc-serialized-server.t $
# $LastChangedRevision: 1297 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings;

use Test::More tests => 13;

use_ok('RPC::Serialized::Server');
can_ok( 'RPC::Serialized::Server', 'new' );
can_ok( 'RPC::Serialized::Server', 'log' );
can_ok( 'RPC::Serialized::Server', 'log_call' );
can_ok( 'RPC::Serialized::Server', 'log_response' );
can_ok( 'RPC::Serialized::Server', 'handler' );
can_ok( 'RPC::Serialized::Server', 'authz_handler' );
can_ok( 'RPC::Serialized::Server', 'recv' );
can_ok( 'RPC::Serialized::Server', 'subject' );
can_ok( 'RPC::Serialized::Server', 'authorize' );
can_ok( 'RPC::Serialized::Server', 'dispatch' );
can_ok( 'RPC::Serialized::Server', 'exception' );
can_ok( 'RPC::Serialized::Server', 'process' );
