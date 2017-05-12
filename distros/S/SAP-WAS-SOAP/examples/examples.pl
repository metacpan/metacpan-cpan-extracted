#!/usr/bin/perl
use strict;
use lib '../lib';
use lib './lib';
use SAP::WAS::SOAP;
#use SOAP::Lite "trace";
use Data::Dumper;
#my $url = 'http://developer:developer\@seahorse.local.net:8000/sap/bc/soap/rfc';
my $url = 'http://seahorse.local.net:8000/sap/bc/soap/rfc';
my $rfcname = 'RFC_READ_REPORT';
my $rfcname2 = 'RFC_READ_TABLE';

my $sapsoap = new SAP::WAS::SOAP( URL => $url, USERID => 'developer', PASSWD => 'developer' );

my $i = $sapsoap->Iface( $rfcname );

$i->Parm('PROGRAM')->value('SAPLGRAP');

$sapsoap->soaprfc( $i );

print "Name:", $i->TRDIR->structure->NAME, "\n";

print "Array of Code Lines ( a hash per line including struture fieldnames ):\n";
print Dumper ( $i->Tab('QTAB')->rows );



print "\n\nGet a table dynamically:\n";
my $i2 = $sapsoap->Iface( $rfcname2 );

$i2->Parm('QUERY_TABLE')->value('T000');
$i2->Parm('ROWCOUNT')->value('1');
$i2->Parm('ROWSKIPS')->value('0');

$sapsoap->soaprfc( $i2 );
print "Array of Table Lines ( a hash per line including struture fieldnames ):\n";
print Dumper ( $i2->Tab('DATA')->rows );

exit 0; 

