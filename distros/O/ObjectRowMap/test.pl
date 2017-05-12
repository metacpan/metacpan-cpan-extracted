#!/usr/bin/env perl

#  Copyright (c) 2002 Craig Welch
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

use warnings;
use strict;

use ObjectRowMapTest;

sub insert {
	my $orm = new ObjectRowMapTest();
	$orm->set('login'=>'me');
	$orm->set('gecos'=>'Myself');
	$orm->set('uid'=>1);
	$orm->set('password'=>'mypass');
	print $orm->get('gecos')."\n";
	$orm->save();
}

sub insert_some {
	my @l = (
		['Two','GeCos','2','p'],
		['Three','GeCos','3','p'],
		['Four','GeCos','4','p']
	);
	foreach my $k (@l) {
		my $orm = new ObjectRowMapTest();
		$orm->set('login'=>$k->[0]);
		$orm->set('gecos'=>$k->[1]);
		$orm->set('uid'=>$k->[2]);
		$orm->set('password'=>$k->[3]);
		$orm->save();
	}
}

sub load {
	my $orm = new ObjectRowMapTest();
	$orm->set('login'=>'me');
	$orm->load();
	print $orm->get('gecos')."\n";
	print $orm->get('uid')."\n";
	print $orm->get('password')."\n";
}

sub update {
	my $orm = new ObjectRowMapTest();
	$orm->set('login'=>'me');
	$orm->load();
	$orm->set('gecos'=>'moosa');
	$orm->set('password'=>'mypass');
	$orm->save();
}

sub xdelete {
	my $orm = new ObjectRowMapTest();
	$orm->set('login'=>'me');
	$orm->load();
	$orm->delete();
}

sub allList {
	my $orm = new ObjectRowMapTest();
	my @all = $orm->allAsList();
	foreach $orm (@all) {
		print $orm->get('login')."\n";
	}
}

print STDERR "You must setup a database and correct connection information before you can test\n";
print STDERR "See example sql, change connection in ObjectRowMapTest.pm\n";
print STDERR "Then remove the exit line in test.pl, there will be no test now\n";
exit 0;
insert();
insert_some();
allList();
load();
update();
load();
xdelete();
