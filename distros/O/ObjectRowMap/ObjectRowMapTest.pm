#!/bin/false

#  Copyright (c) 2002 Craig Welch
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

package ObjectRowMapTest;

use warnings;
use strict;

use vars qw( @ISA );
use ObjectRowMap;
push @ISA, 'ObjectRowMap';


my $ormapProps;
if (!defined($ormapProps)) {
	$ormapProps = { 'table'=>'test','keyFields'=>['login','uid'],'dbhConnectArgs'=>["DBI:Pg:dbname=ormaptest",'login','password',{'AutoCommit'=>0}],'persistFields'=>{'login'=>'','uid'=>'','password'=>'','gecos'=>''},'debug'=>0,'commitOnSave'=>1};
}

sub ormapProperties {
	return $ormapProps;
}

sub preSave_password {
	my $self = shift;
	my $pass = shift;
	$pass .= "_SUPERENCRYPTED";
	return $pass;
}

sub postLoad_password {
	my $self = shift;
	my $pass = shift;
	$pass =~ s/_SUPERENCRYPTED//;
	return $pass;
}

sub get_uid {
	my $self = shift;
	my $uid = shift;
	print STDERR "Get Intercepted uid $uid\n";
	return $uid;
}

sub set_uid {
	my $self = shift;
	my $uid = shift;
	print STDERR "Set Intercepted uid $uid, adding 10 for kicks\n";
	$uid = $uid + 10;
	return $uid;
}


