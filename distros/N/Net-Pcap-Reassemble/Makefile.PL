use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# $Id: Makefile.PL,v 1.2 2006/11/17 15:40:32 james Exp $
WriteMakefile(
    'NAME'	=> 'Net::Pcap::Reassemble',
    'VERSION_FROM' => 'Reassemble.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'Reassemble.pm',
    'LICENSE' => 'perl',
    'PREREQ_PM'	=> { "Net::Pcap" => "0" },
    'dist'	=> { POSTOP=>'$(CHMOD) 444 $(DISTVNAME).tar$(SUFFIX)' },
);
