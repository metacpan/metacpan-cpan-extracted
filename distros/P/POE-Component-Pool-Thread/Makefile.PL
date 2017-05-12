#!/usr/bin/perl

use strict;
use warnings FATAL => "all";
use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open CHANGES, ">>CHANGES" and close CHANGES;

# Dont laugh!
#sub MY::postamble { 
#	q(
#document:
#	$(NOECHO) $(PERLRUN) "-MFile::Find"                       \
#	 -le 'find { wanted => sub { if (m/otl$$/) { \
#	 		my $$pod = $$_; \
#			$$pod =~ s/otl/pod/; \
#			print "Converting $$File::Find::name to $$pod"; \
#			system("otl2pod $$_ > $$pod"); \
#		} } }, "lib";'
#	 );
#}

WriteMakefile
  ( NAME         => 'POE::Component::Pool::Thread',
    AUTHOR       => 'Scott S. McCoy (tag@cpan.org)',
    ABSTRACT     => 'A POE Component for managing Boss/Worker Thread pools',
    VERSION_FROM => 'Thread.pm',

    PREREQ_PM    => {
        POE      => 0.30,
        threads  => 1.03,
    },

    dist         =>
    { DIST_DEFAULT => "tardist",
	  COMPRESS   => 'gzip -9f',
      SUFFIX     => 'gz',
      PREOP      => ( 'svn log | ' .
                      'tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
                    ),
    },
  );
