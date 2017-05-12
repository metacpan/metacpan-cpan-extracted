#! /usr/bin/perl -w
#*********************************************************************
#*** t/12LBExecute.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 22LBExecute.t,v 1.3 2003-01-20 18:59:16 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Factory;
use ResourcePool::LoadBalancer;
use ResourcePool::Command;

package MyTestCommandOK;

use vars qw(@ISA);
push @ISA, qw(ResourcePool::Command);

sub new($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);

	$self->setCalled(0);
	return $self;
}

sub execute($$) {
	my ($self, $resource) = @_;
	$self->setCalled($self->getCalled()+1);
	$self->setResource($resource->{ARGUMENT});
	return 1;
}

# i start to like get/set methods for perl, because they enable
# compiletime checking of typos
sub setCalled($$) {
	my ($self, $val) = @_;
	$self->{called} = $val;
}

sub getCalled($) {
	my ($self) = @_;
	return $self->{called};
}

sub setResource($$) {
	my ($self, $rec) = @_;
	$self->{resource}->{$rec} = $rec;
}

sub getResource($) {
	my ($self) = @_;
	return $self->{resource};
}

package MyTestCommandReturnFalse;

push @MyTestCommandReturnFalse::ISA, qw(MyTestCommandOK);

sub execute($$) {
	my ($self, @args) = @_;
	$self->SUPER::execute(@args);
	return 0;
}

package MyTestCommandReturnArgument;

push @MyTestCommandReturnArgument::ISA, qw(MyTestCommandOK);

sub execute($$$) {
	my ($self, $resource, $arg) = @_;
	$self->SUPER::execute($resource);
	return $arg;
}

package MyTestCommandDie;

push @MyTestCommandDie::ISA, qw(MyTestCommandOK);

sub execute($$) {
	my ($self, @args) = @_;
	$self->SUPER::execute(@args);
	die;
}

package main;


BEGIN { plan tests => 15; };

# there shall be silence
$SIG{'__WARN__'} = sub {};


my $f1 = ResourcePool::Factory->new('f1');
my $p1 = ResourcePool->new($f1, MaxExecTry => 1);
my $f2 = ResourcePool::Factory->new('f2');
my $p2 = ResourcePool->new($f2, MaxExecTry => 1);
my $lb = ResourcePool::LoadBalancer->new('mykey', MaxExecTry => 4, SleepOnFail=>0);
$lb->add_pool($p1, SuspendTimeout => 0);
$lb->add_pool($p2, SuspendTimeout => 0);
my ($cmd, $rc, $rec);

$cmd = new MyTestCommandOK();
$rc = $lb->execute($cmd);
ok ($rc == 1);
ok ($cmd->getCalled() == 1);
$rec = $cmd->getResource();
ok (defined $rec->{f1} && ! defined $rec->{f2});

$cmd = new MyTestCommandReturnFalse();
$rc = $lb->execute($cmd);
ok ($rc == 0);
ok ($cmd->getCalled() == 1);
$rec = $cmd->getResource();
ok ((defined $rec->{f1} && !defined $rec->{f2}) || (!defined $rec->{f1} && defined $rec->{f2}));

$cmd = new MyTestCommandDie();
eval {
	$rc = $lb->execute($cmd);
};
ok ($@);
ok ($cmd->getCalled() == 4);
$rec = $cmd->getResource();
ok (defined $rec->{f1} && defined $rec->{f2});


$cmd = new MyTestCommandReturnArgument();
$rc = $lb->execute($cmd, 'elch');
ok ($rc eq 'elch');
ok ($cmd->getCalled() == 1);
$rec = $cmd->getResource();
ok ((defined $rec->{f1} && !defined $rec->{f2}) || (!defined $rec->{f1} && defined $rec->{f2}));

$rc = $lb->execute($cmd, 'hirsch');
ok ($rc eq 'hirsch');
ok ($cmd->getCalled() == 2);
$rec = $cmd->getResource();
ok (defined $rec->{f1} && defined $rec->{f2});
