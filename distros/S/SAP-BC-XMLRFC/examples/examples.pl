#!/usr/bin/perl
use strict;
use lib '../lib';
use SAP::BC::XMLRFC;

my $userid = 'Administrator';
my $passwd = 'manage';
my $server="http://kogut.local.net:5555";
my $service = 'WAS:readReport';
my $service2 = 'WAS:readTable';

my $xmlrfc = new SAP::BC::XMLRFC( SERVER => $server,
				  USERID => $userid,
				  PASSWD => $passwd );

my $i = $xmlrfc->Iface( $service );

$i->Parm('PROGRAM')->value('SAPLGRAP');

$xmlrfc->xmlrfc( $i );

# Autoload the Parameter name
print "Name:", $i->TRDIR->structure->NAME, "\n";

print "Array of Code Lines:\n";
map {print @{$_}, "\n"  } ( $i->Tab('QTAB')->rows );

print "And again by row: \n";

#Autoload the table name
while ( my $row = $i->QTAB->nextrow ){
    map { print "$_ = $row->{$_} \n" } keys %{$row};
};

print "\n\nGet a table dynamically:\n";
my $i2 = $xmlrfc->Iface( $service2 );

$i2->Parm('QUERY_TABLE')->value('T000');
$i2->Parm('ROWCOUNT')->value('1');
$i2->Parm('ROWSKIPS')->value('0');

$xmlrfc->xmlrfc( $i2 );

map {print @{$_}, "\n"  } ( $i2->Tab('DATA')->rows );

exit 0; 

