#!/usr/bin/perl -w
#

use ExtUtils::testlib;
use Net::NfDump ':all';


# instance of source and destination files
my $flow = new Net::NfDump(
					OutputFile => "rec.tmp",
					Fields => 'connid,srcip,srcport,dstip,dstport,
					xsrcip,xsrcport,xdstip,xdstport,
					proto,first,flowstart,inif,outif,bytes,pkts,tcpflags,event,xevent' 
				);


$flow->storerow_array(
	71434019, txt2ip('192.168.20.30'), 60268, txt2ip('8.8.8.8'), 53, 
	undef, undef, undef, undef, 
	17, 1361206834000, 1361206834000, 4, 3, 116, 6666, 0, 2, 3	);

$flow->storerow_array(
	71434019, txt2ip('192.168.20.30'), 60268, txt2ip('8.8.8.8'), 53, 
	undef, 1111, undef, 2222,
	17, 1361206834000, 1361206834000, 4, 3, 116, 6666, 0, 2, 3	);

#$flow->storerow_array(
#	71434019, '192.168.20.30', 60268, '8.8.8.8', 53, 
#	0, 111, 0, 555, 
#	17, 1361206834000, 1361206834000, 4, 3, 116, 6666, 0, 2, 3	);
$flow->finish();



