#!/usr/bin/perl
use lib '../lib';
use strict;
use SAP::BC::XMLRFC;

my $userid = 'Administrator';
my $passwd = 'manage';
my $server="http://kogut.local.net:5555";
my $service = 'WAS:readReport';

die "no report name supplied - eg. usage: $0 SAPLGRAP " unless $ARGV[0];

my $xmlrfc = new SAP::BC::XMLRFC( SERVER => $server,
				  USERID => $userid,
				  PASSWD => $passwd );

my $i = $xmlrfc->Iface( $service );

$i->Parm('PROGRAM')->value($ARGV[0]);

$xmlrfc->xmlrfc( $i );

print "Name:", $i->Parm('TRDIR')->structure->NAME, "\n";

map {print @{$_}, "\n"  } ( $i->Tab('QTAB')->rows );















