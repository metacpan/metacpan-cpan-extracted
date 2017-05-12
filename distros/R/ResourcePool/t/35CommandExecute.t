#! /usr/bin/perl -w
#*********************************************************************
#*** t/12PoolExecute.t
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 35CommandExecute.t,v 1.2 2003-03-16 16:55:27 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Factory;
use ResourcePool::Command::NoFailoverException;
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

package MyTestCommandNoFailoverException;

push @MyTestCommandNoFailoverException::ISA, qw(MyTestCommandOK);

sub execute($$) {
	my ($self, @args) = @_;
	$self->SUPER::execute(@args);
	die ResourcePool::Command::NoFailoverException->new;
}

package FunkyException;

push @FunkyException::ISA, qw(ResourcePool::Command::NoFailoverException);

sub new($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{ex} = shift;
	return $self;
}

sub ex($) {
	my ($self) = @_;
	return $self->{ex};
}

package MyTestCommandFunkyException;

push @MyTestCommandFunkyException::ISA, qw(MyTestCommandOK);

sub execute($$) {
    my ($self, @args) = @_;
    $self->SUPER::execute(@args);
    die FunkyException->new('very funky');
}

package MyTestCommandAllHooks;

push @MyTestCommandAllHooks::ISA, qw(MyTestCommandOK);

sub new($$$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->{ex} = shift;
	$self->{where} = shift;
	$self->{cnt}->{init} = 0;
	$self->{cnt}->{preExecute} = 0;
	$self->{cnt}->{execute} = 0;
	$self->{cnt}->{postExecute} = 0;
	$self->{cnt}->{cleanup} = 0;
	return $self;
}

sub init() {
	my ($self) = @_;
	$self->{cnt}->{init}++;
	if ($self->{where} eq 'init') {
		die $self->{ex};
	}
}

sub preExecute() {
	my ($self, $r) = @_;
	$self->{cnt}->{preExecute}++;
	if ($self->{where} eq 'preExecute') {
		die $self->{ex};
	}
}

sub execute() {
	my ($self, $r) = @_;
	$self->{cnt}->{execute}++;
	if ($self->{where} eq 'execute') {
		die $self->{ex};
	}
}

sub postExecute() {
	my ($self, $r) = @_;
	$self->{cnt}->{postExecute}++;
	if ($self->{where} eq 'postExecute') {
		die $self->{ex};
	}
}

sub cleanup() {
	my ($self) = @_;
	$self->{cnt}->{cleanup}++;
	if ($self->{where} eq 'cleanup') {
		die $self->{ex};
	}
}


package main;

BEGIN { plan tests => 85; };

# there shall be silence
$SIG{'__WARN__'} = sub {};


my $f1 = ResourcePool::Factory->new('f1');
my $p1 = ResourcePool->new($f1, MaxExecTry => 4);
my ($cmd, $rc);

$cmd = new MyTestCommandOK();
$rc = $p1->execute($cmd);
ok ($rc == 1);
ok ($cmd->getCalled() == 1);

$cmd = new MyTestCommandReturnFalse();
$rc = $p1->execute($cmd);
ok ($rc == 0);
ok ($cmd->getCalled() == 1);

$cmd = new MyTestCommandDie();
eval {
	$rc = $p1->execute($cmd);
};
ok ($@);
ok ($cmd->getCalled() == 4);

$cmd = new MyTestCommandNoFailoverException();
eval {
	$rc = $p1->execute($cmd);
};

ok ($@);
ok ($cmd->getCalled() == 1);

$cmd = new MyTestCommandFunkyException();
eval {
	$rc = $p1->execute($cmd);
};
ok ($@);
ok ($@->getException());
ok ($@->getException()->ex() eq 'very funky');
ok ($cmd->getCalled() == 1);


$cmd = new MyTestCommandReturnArgument();
$rc = $p1->execute($cmd, 'elch');
ok ($rc eq 'elch');
ok ($cmd->getCalled() == 1);

$rc = $p1->execute($cmd, 'hirsch');
ok ($rc eq 'hirsch');
ok ($cmd->getCalled() == 2);


$rc = ResourcePool::Command::Execute::execute($p1, $cmd, 'reh');
ok ($rc eq 'reh');

###### normal case
$cmd = MyTestCommandAllHooks->new("hirsch", "reh"); #will not throw
eval {
$rc = ResourcePool::Command::Execute::execute($p1, $cmd);
};
print $@;
ok (!$@);
# normal case, everything should have been executed once
ok ($cmd->{cnt}->{init} == 1);
ok ($cmd->{cnt}->{preExecute} == 1);
ok ($cmd->{cnt}->{execute} == 1);
ok ($cmd->{cnt}->{postExecute} == 1);
ok ($cmd->{cnt}->{cleanup} == 1);


###### init throws
$cmd = MyTestCommandAllHooks->new("hirsch\n", "init"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
my $ex = $@;
ok ($ex);
ok ($ex->rootException() eq "hirsch\n");
ok ($cmd->{cnt}->{init} == 4);
ok ($cmd->{cnt}->{preExecute} == 0);
ok ($cmd->{cnt}->{execute} == 0);
ok ($cmd->{cnt}->{postExecute} == 0);
ok ($cmd->{cnt}->{cleanup} == 0);

###### preExecute throws
$cmd = MyTestCommandAllHooks->new("hirsch\n", "preExecute"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok ($ex);
ok ($ex->rootException() eq "hirsch\n");
ok ($cmd->{cnt}->{init} == 4);
ok ($cmd->{cnt}->{preExecute} == 4);
ok ($cmd->{cnt}->{execute} == 0);
ok ($cmd->{cnt}->{postExecute} == 0);
ok ($cmd->{cnt}->{cleanup} == 4);


###### Execute throws
$cmd = MyTestCommandAllHooks->new("reh\n", "execute"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok ($ex);
ok ($ex->rootException() eq "reh\n");
ok ($cmd->{cnt}->{init} == 4);
ok ($cmd->{cnt}->{preExecute} == 4);
ok ($cmd->{cnt}->{execute} == 4);
ok ($cmd->{cnt}->{postExecute} == 0);
ok ($cmd->{cnt}->{cleanup} == 4);

###### PostExecute throws
$cmd = MyTestCommandAllHooks->new("reh\n", "postExecute"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok ($ex);
ok ($ex->rootException() eq "reh\n");
ok ($cmd->{cnt}->{init} == 4);
ok ($cmd->{cnt}->{preExecute} == 4);
ok ($cmd->{cnt}->{execute} == 4);
ok ($cmd->{cnt}->{postExecute} == 4);
ok ($cmd->{cnt}->{cleanup} == 4);


###### cleanup throws always handled as NoFailoverException
$cmd = MyTestCommandAllHooks->new("reh", "cleanup"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok (!$ex);
ok ($cmd->{cnt}->{init} == 1);
ok ($cmd->{cnt}->{preExecute} == 1);
ok ($cmd->{cnt}->{execute} == 1);
ok ($cmd->{cnt}->{postExecute} == 1);
ok ($cmd->{cnt}->{cleanup} == 1);

#####
#
# check with NoFailoverException
#
#####

my $nfe = ResourcePool::Command::NoFailoverException->new("reh");
###### init throws
$cmd = MyTestCommandAllHooks->new($nfe, "init"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok ($ex);
ok ($ex->rootException() eq "reh");
ok ($cmd->{cnt}->{init} == 1);
ok ($cmd->{cnt}->{preExecute} == 0);
ok ($cmd->{cnt}->{execute} == 0);
ok ($cmd->{cnt}->{postExecute} == 0);
ok ($cmd->{cnt}->{cleanup} == 0);

##### preExecute throws
$cmd = MyTestCommandAllHooks->new($nfe, "preExecute"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok ($ex);
ok ($ex->rootException() eq "reh");
ok ($cmd->{cnt}->{init} == 1);
ok ($cmd->{cnt}->{preExecute} == 1);
ok ($cmd->{cnt}->{execute} == 0);
ok ($cmd->{cnt}->{postExecute} == 0);
ok ($cmd->{cnt}->{cleanup} == 1);


###### Execute throws
$cmd = MyTestCommandAllHooks->new($nfe, "execute"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok ($ex);
ok ($ex->rootException() eq "reh");
ok ($cmd->{cnt}->{init} == 1);
ok ($cmd->{cnt}->{preExecute} == 1);
ok ($cmd->{cnt}->{execute} == 1);
ok ($cmd->{cnt}->{postExecute} == 0);
ok ($cmd->{cnt}->{cleanup} == 1);

###### postExecute throws
$cmd = MyTestCommandAllHooks->new($nfe, "postExecute"); #will throw
eval { $rc = ResourcePool::Command::Execute::execute($p1, $cmd); };
$ex = $@;
ok ($ex);
ok ($ex->rootException() eq "reh");
ok ($cmd->{cnt}->{init} == 1);
ok ($cmd->{cnt}->{preExecute} == 1);
ok ($cmd->{cnt}->{execute} == 1);
ok ($cmd->{cnt}->{postExecute} == 1);
ok ($cmd->{cnt}->{cleanup} == 1);

