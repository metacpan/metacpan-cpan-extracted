#!/usr/bin/perl
# $Id: Makefile.PL,v 1.3 2003/07/08 15:39:01 fletch Exp $

use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME         => 'POE::Component::Pcap',
    AUTHOR       => 'Mike Fletcher <fletch+poe@phydeaux.org>',
    ABSTRACT     => 'POE component for non-blocking use of Net::Pcap.',
    VERSION_FROM => 'Pcap.pm',

    PM           => { 'Pcap.pm' => '$(INST_LIBDIR)/Pcap.pm' },
    PREREQ_PM    => { POE      => 0.26,
                      Net::Pcap => 0.04,
		      NetPacket::Ethernet => 0.01,
                    },
    dist         => { COMPRESS => 'gzip -9f',
                      SUFFIX   => 'gz',
                    },
  );
