#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/60-rpc-serialized-authz-handler.t $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

use_ok('RPC::Serialized::AuthzHandler');
can_ok( 'RPC::Serialized::AuthzHandler', 'new' );
can_ok( 'RPC::Serialized::AuthzHandler', 'check_authz' );

my $ah = RPC::Serialized::AuthzHandler->new();
isa_ok( $ah, 'RPC::Serialized::AuthzHandler' );
ok( $ah->check_authz() );
ok( $ah->check_authz( 'foo', 'create', 'bar' ) );
