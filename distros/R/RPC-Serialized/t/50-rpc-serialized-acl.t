#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/t/50-rpc-serialized-acl.t $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 101;

use_ok('RPC::Serialized::ACL');
use_ok('RPC::Serialized::ACL::Operation');
use_ok('RPC::Serialized::ACL::Subject');
use_ok('RPC::Serialized::ACL::Target');
use_ok('RPC::Serialized::ACL::Group');

can_ok( 'RPC::Serialized::ACL', 'new' );
can_ok( 'RPC::Serialized::ACL', 'operation' );
can_ok( 'RPC::Serialized::ACL', 'subject' );
can_ok( 'RPC::Serialized::ACL', 'target' );
can_ok( 'RPC::Serialized::ACL', 'action' );
can_ok( 'RPC::Serialized::ACL', 'check' );

sub mk_group_file {
    require File::Temp;
    require URI::file;
    my ( $fh, $path ) = File::Temp::tempfile( UNLINK => 1 );
    $fh->print( join( "\n", @_ ) . "\n" );
    $fh->close();
    return URI::file->new($path);
}

my $op_create = RPC::Serialized::ACL::Operation->new('create');
my $op_all    = RPC::Serialized::ACL::Operation->new('ALL');
my $subj_foo  = RPC::Serialized::ACL::Subject->new('foo');
my $subj_all  = RPC::Serialized::ACL::Subject->new('ALL');
my $tgt_bar   = RPC::Serialized::ACL::Target->new('bar');
my $tgt_all   = RPC::Serialized::ACL::Target->new('ALL');

my @group_a = qw(foo bar baz);
my $group_a = RPC::Serialized::ACL::Group->new( mk_group_file(@group_a) );

my @group_b = qw(bar baz quux);
my $group_b = RPC::Serialized::ACL::Group->new( mk_group_file(@group_b) );

my $acl = RPC::Serialized::ACL->new(
    operation => $op_create,
    subject   => $subj_foo,
    target    => $tgt_bar,
    action    => 'allow'
);
isa_ok( $acl, 'RPC::Serialized::ACL' );
is( $acl->operation,       $op_create );
is( $acl->subject,         $subj_foo );
is( $acl->target,          $tgt_bar );
is( $acl->operation->name, 'create' );
is( $acl->subject->name,   'foo' );
is( $acl->target->name,    'bar' );
is( $acl->action,          RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'bar', 'create',  'bar' ), RPC::Serialized::ACL->DECLINE );
is( $acl->check( 'foo', 'destroy', 'bar' ), RPC::Serialized::ACL->DECLINE );
is( $acl->check( 'foo', 'create',  'foo' ), RPC::Serialized::ACL->DECLINE );

$acl = RPC::Serialized::ACL->new(
    operation => 'create',
    subject   => 'foo',
    target    => 'bar',
    action    => 'allow'
);
isa_ok( $acl,            'RPC::Serialized::ACL' );
isa_ok( $acl->operation, 'RPC::Serialized::ACL::Operation' );
isa_ok( $acl->subject,   'RPC::Serialized::ACL::Subject' );
isa_ok( $acl->target,    'RPC::Serialized::ACL::Target' );
is( $acl->operation->name, 'create' );
is( $acl->subject->name,   'foo' );
is( $acl->target->name,    'bar' );
is( $acl->action,          RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'bar', 'create',  'bar' ), RPC::Serialized::ACL->DECLINE );
is( $acl->check( 'foo', 'destroy', 'bar' ), RPC::Serialized::ACL->DECLINE );
is( $acl->check( 'foo', 'create',  'foo' ), RPC::Serialized::ACL->DECLINE );

$acl = RPC::Serialized::ACL->new(
    operation => $op_create,
    subject   => $subj_foo,
    target    => $tgt_bar,
    action    => 'deny'
);
isa_ok( $acl, 'RPC::Serialized::ACL' );
is( $acl->operation, $op_create );
is( $acl->subject,   $subj_foo );
is( $acl->target,    $tgt_bar );
is( $acl->action,    RPC::Serialized::ACL->DENY );
is( $acl->check( 'foo', 'create',  'bar' ), RPC::Serialized::ACL->DENY );
is( $acl->check( 'bar', 'create',  'bar' ), RPC::Serialized::ACL->DECLINE );
is( $acl->check( 'foo', 'destroy', 'bar' ), RPC::Serialized::ACL->DECLINE );
is( $acl->check( 'foo', 'create',  'foo' ), RPC::Serialized::ACL->DECLINE );

$acl = RPC::Serialized::ACL->new(
    operation => $op_all,
    subject   => $subj_foo,
    target    => $tgt_bar,
    action    => 'allow'
);
isa_ok( $acl, 'RPC::Serialized::ACL' );
is( $acl->operation, $op_all );
is( $acl->subject,   $subj_foo );
is( $acl->target,    $tgt_bar );
is( $acl->action,    RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'bar', 'create',  'bar' ), RPC::Serialized::ACL->DECLINE );
is( $acl->check( 'foo', 'destroy', 'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'foo' ), RPC::Serialized::ACL->DECLINE );

$acl = RPC::Serialized::ACL->new(
    operation => $op_all,
    subject   => $subj_all,
    target    => $tgt_bar,
    action    => 'allow'
);
isa_ok( $acl, 'RPC::Serialized::ACL' );
is( $acl->operation, $op_all );
is( $acl->subject,   $subj_all );
is( $acl->target,    $tgt_bar );
is( $acl->action,    RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'bar', 'create',  'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'destroy', 'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'foo' ), RPC::Serialized::ACL->DECLINE );

$acl = RPC::Serialized::ACL->new(
    operation => $op_all,
    subject   => $subj_all,
    target    => $tgt_all,
    action    => 'allow'
);
isa_ok( $acl, 'RPC::Serialized::ACL' );
is( $acl->operation, $op_all );
is( $acl->subject,   $subj_all );
is( $acl->target,    $tgt_all );
is( $acl->action,    RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'bar', 'create',  'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'destroy', 'bar' ), RPC::Serialized::ACL->ALLOW );
is( $acl->check( 'foo', 'create',  'foo' ), RPC::Serialized::ACL->ALLOW );

$acl = RPC::Serialized::ACL->new(
    operation => $op_create,
    subject   => $group_a,
    target    => $tgt_bar,
    action    => 'allow'
);
isa_ok( $acl, 'RPC::Serialized::ACL' );
is( $acl->operation, $op_create );
is( $acl->subject,   $group_a );
is( $acl->target,    $tgt_bar );
is( $acl->action,    RPC::Serialized::ACL->ALLOW );
isa_ok( $acl->subject, 'RPC::Serialized::ACL::Group' );

foreach my $s (@group_a) {
    is( $acl->check( $s, 'create',  'bar' ), $acl->ALLOW );
    is( $acl->check( $s, 'destroy', 'bar' ), $acl->DECLINE );
    is( $acl->check( $s, 'create',  'foo' ), $acl->DECLINE );
}
is( $acl->check( 'not_in_group_a', 'create', 'bar' ), $acl->DECLINE );

$acl = RPC::Serialized::ACL->new(
    operation => $op_create,
    subject   => $subj_foo,
    target    => $group_b,
    action    => 'deny'
);
is( $acl->operation, $op_create );
is( $acl->subject,   $subj_foo );
is( $acl->target,    $group_b );
is( $acl->action,    $acl->DENY );
foreach my $t (@group_b) {
    is( $acl->check( 'foo', 'create',  $t ), $acl->DENY );
    is( $acl->check( 'foo', 'destroy', $t ), $acl->DECLINE );
    is( $acl->check( 'bar', 'create',  $t ), $acl->DECLINE );
}
is( $acl->check( 'foo', 'create', 'not_in_group_b' ), $acl->DECLINE );
