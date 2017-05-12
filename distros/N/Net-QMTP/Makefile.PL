use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# $Id: Makefile.PL,v 1.4 2003/06/25 13:42:39 james Exp $
WriteMakefile(
    'NAME'	=> 'Net::QMTP',
    'VERSION_FROM' => 'QMTP.pm', # finds $VERSION
    'PREREQ_PM'	=> { "Text::Netstring" => "0.04" },
    'dist'	=> { POSTOP=>'$(CHMOD) 444 $(DISTVNAME).tar$(SUFFIX)' },
);
