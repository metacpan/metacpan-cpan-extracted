#!/usr/bin/perl

use strict;
use warnings FATAL => "all";
use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open CHANGES, ">>CHANGES" and close CHANGES;

# Dont laugh!
sub MY::postamble { 
	q(
document:
	 $(NOECHO) $(PERLRUN) "-MFile::Find" -le 'find sub { if (m/otl$$/) { my $$pod = $$_; $$pod =~ s/otl/pod/g; system "otl2pod $$_ > $$pod" } }, "lib"'

upload: document dist
	cpan-upload $(DISTNAME)-$(VERSION).tar.gz
	 );
}

WriteMakefile
  ( NAME         => 'POE::Component::Client::TCPMulti',
    AUTHOR       => 'Scott S. McCoy (tag@cpan.org)',
    ABSTRACT     => 'POE component for High Connectivity TCP Clients',
    VERSION_FROM => 'lib/POE/Component/Client/TCPMulti.pm',

#   PM           => 
#   { 'lib/POE/Component/Client/TCPMulti.pm' => '$(INST_LIBDIR)/lib/POE/Component/Client/TCPMulti.pm' },
#	MAN3PODS	 =>
#	{ 'TCPMulti.pod' => '$(INST_MAN3DIR)/POE::Component::Client::TCPMulti' },

	PMLIBDIRS	 => ['lib'], # This is to make the autopodfinder shit work.

    PREREQ_PM    => { 
        POE      => 0.11, 
    },

    dist         =>
    { DIST_DEFAULT => "tardist document",
	  COMPRESS   => 'gzip -9f',
      SUFFIX     => 'gz',
      PREOP      => ( 'svn log | ' .
                      'tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
                    ),
    },
  );
