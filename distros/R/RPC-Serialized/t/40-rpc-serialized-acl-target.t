#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/40-rpc-serialized-acl-target.t $
# $LastChangedRevision: 1323 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;

use_ok('RPC::Serialized::ACL::Target');
can_ok( 'RPC::Serialized::ACL::Target', 'new' );
can_ok( 'RPC::Serialized::ACL::Target', 'name' );
can_ok( 'RPC::Serialized::ACL::Target', 'match' );

eval { RPC::Serialized::ACL::Target->new() };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'Target name not specified' );

my $tgt = RPC::Serialized::ACL::Target->new('ALL');
isa_ok( $tgt, 'RPC::Serialized::ACL::Target' );
is( $tgt->name(), 'ALL' );
ok( $tgt->match() );
ok( $tgt->match('foo') );

$tgt = RPC::Serialized::ACL::Target->new('foo');
isa_ok( $tgt, 'RPC::Serialized::ACL::Target' );
is( $tgt->name, 'foo' );
ok( $tgt->match('foo') );
ok( not $tgt->match('bar') );
ok( not $tgt->match('food') );
ok( not $tgt->match() );
