# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2003-2020 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
######################################################################

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
    q{
all::

preexist:
	svnorcvs nexists $(DISTNAME)_$(VERSION_SYM)

tag:
	svnorcvs tag  $(DISTNAME)_$(VERSION_SYM)

maintainer-diff:
	svnorcvs diff $(DISTNAME)_$(VERSION_SYM)

maintainer-dist: preexist dist tag
	svnorcvs release $(DISTVNAME).tar.gz

maintainer-clean: distclean
	-$(RM_RF) README

maintainer-copy:

clean::
	-$(RM_RF) test_dir
};
}

WriteMakefile(
	      VERSION_FROM => 'lib/Parallel/Forker.pm',
	      DISTNAME  => 'Parallel-Forker',
	      NAME      => 'Parallel::Forker',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT  => 'Parallel job forking and management, with expression based control',
	      PREREQ_PM => {'Proc::ProcessTable' => 0.40,
			    'Scalar::Util' => 0,
			    'Test::More' => 0,
			    'Time::HiRes' => 0,
			},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz',
			    DIST_DEFAULT => 'all tardist',
			},
	      );

