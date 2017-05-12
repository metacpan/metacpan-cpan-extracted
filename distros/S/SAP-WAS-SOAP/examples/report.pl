#!/usr/bin/perl
use lib '../lib';
use strict;
use SAP::WAS::SOAP;
use Data::Dumper;

my $url = 'http://localhost:8080/sap/bc/soap/rfc';
my $rfcname = 'RFC_READ_REPORT';

die "no report name supplied - eg. usage: $0 SAPLGRAP " unless $ARGV[0];

my $sapsoap = new SAP::WAS::SOAP( URL => $url );

my $i = $sapsoap->Iface( $rfcname );

$i->Parm('PROGRAM')->value($ARGV[0]);

$sapsoap->soaprfc( $i );

print "Name:", $i->Parm('TRDIR')->structure->NAME, "\n";

print Dumper ( $i->Tab('QTAB')->rows );

