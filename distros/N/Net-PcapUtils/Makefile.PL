#
# Makefile for Net::PcapUtils module
#
# $Id: Makefile.PL,v 1.5 1999/04/07 01:44:52 tpot Exp $
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Net::PcapUtils',
    DISTNAME => 'Net-PcapUtils',
    VERSION_FROM => 'PcapUtils.pm',
    dist => {
	'COMPRESS' => 'gzip -9f',
	'SUFFIX' => 'gz'
	},
    PREREQ_PM => {
        'Net::Pcap' => 0.03
      },
);

