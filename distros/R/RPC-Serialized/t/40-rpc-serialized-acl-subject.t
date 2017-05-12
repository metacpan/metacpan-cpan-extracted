#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/40-rpc-serialized-acl-subject.t $
# $LastChangedRevision: 1323 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;

use_ok('RPC::Serialized::ACL::Subject');
can_ok( 'RPC::Serialized::ACL::Subject', 'new' );
can_ok( 'RPC::Serialized::ACL::Subject', 'name' );
can_ok( 'RPC::Serialized::ACL::Subject', 'match' );

eval { RPC::Serialized::ACL::Subject->new() };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'Subject name not specified' );

my $subj = RPC::Serialized::ACL::Subject->new('ALL');
isa_ok( $subj, 'RPC::Serialized::ACL::Subject' );
is( $subj->name(), 'ALL' );
ok( $subj->match() );
ok( $subj->match('foo') );

$subj = RPC::Serialized::ACL::Subject->new('foo');
isa_ok( $subj, 'RPC::Serialized::ACL::Subject' );
is( $subj->name, 'foo' );
ok( $subj->match('foo') );
ok( not $subj->match('bar') );
ok( not $subj->match('food') );
ok( not $subj->match() );
