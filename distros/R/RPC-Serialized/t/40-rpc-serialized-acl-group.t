#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/40-rpc-serialized-acl-group.t $
# $LastChangedRevision: 1323 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;

use_ok('RPC::Serialized::ACL::Group');
can_ok( 'RPC::Serialized::ACL::Group', 'new' );
can_ok( 'RPC::Serialized::ACL::Group', 'is_member' );
can_ok( 'RPC::Serialized::ACL::Group', 'match' );
ok( not RPC::Serialized::ACL::Group->is_member('foo') );
ok( not RPC::Serialized::ACL::Group->match('foo') );

eval { RPC::Serialized::ACL::Group->new() };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, "URI not specified" );

eval { RPC::Serialized::ACL::Group->new("garbage") };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, "Failed to parse scheme from URI 'garbage'" );

eval { RPC::Serialized::ACL::Group->new("http://www.foo.com/") };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, "Unsupported URI scheme 'http'" );
