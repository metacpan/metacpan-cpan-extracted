#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/40-rpc-serialized-acl-operation.t $
# $LastChangedRevision: 1323 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;

use_ok('RPC::Serialized::ACL::Operation');
can_ok( 'RPC::Serialized::ACL::Operation', 'new' );
can_ok( 'RPC::Serialized::ACL::Operation', 'name' );
can_ok( 'RPC::Serialized::ACL::Operation', 'match' );

eval { RPC::Serialized::ACL::Operation->new() };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'Operation name not specified' );

my $op = RPC::Serialized::ACL::Operation->new('ALL');
isa_ok( $op, 'RPC::Serialized::ACL::Operation' );
is( $op->name(), 'ALL' );
ok( $op->match() );
ok( $op->match('foo') );

$op = RPC::Serialized::ACL::Operation->new('foo');
isa_ok( $op, 'RPC::Serialized::ACL::Operation' );
is( $op->name, 'foo' );
ok( $op->match('foo') );
ok( not $op->match('bar') );
ok( not $op->match('food') );
ok( not $op->match() );
