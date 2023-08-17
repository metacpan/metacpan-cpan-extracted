#!/usr/bin/perl -w

use strict;

use BER;
use SNMP_Session;
use SNMP_util "0.86";

snmpmapOID (qw(locIfInBitsSec	1.3.6.1.4.1.9.2.2.1.1.6
	       locIfOutBitsSec	1.3.6.1.4.1.9.2.2.1.1.8
	       locIfDescr	1.3.6.1.4.1.9.2.2.1.1.28));

sub usage () { die "Usage: $0 community\@host\n"; }

my $host = shift @ARGV || usage ();

snmpmaptable ($host,
	      sub {
		  my ($index, $descr, $in, $out, $comment) = @_;

		  printf "%2d  %-24s %10s %10s %s\n",
		  $index,
		  defined $descr ? $descr : '',
		  defined $in ? $in/1000.0 : '-',
		  defined $out ? $out/1000.0 : '-',
		  defined $comment ? $comment : '';
	      },
	      qw(ifDescr locIfInBitsSec locIfOutBitsSec locIfDescr));
