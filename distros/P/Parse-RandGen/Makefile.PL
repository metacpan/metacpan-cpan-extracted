# $Revision: #3 $$Date: 2005/07/18 $$Author: jd150722 $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2003-2005 by Jeff Dutton.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

$DOLLAR = '$$';	# Quoted properly for make
sub MY::postamble {
"
README: readme.texi
	-rm -f \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

clean::
	-rm -rf test_dir

dist: maintainer-copy distcheck README

## Maintainer use:
tag:
	c4 label -d     \$(DISTNAME)_\$(VERSION_SYM) || true
	c4 label        \$(DISTNAME)_\$(VERSION_SYM)
	c4 labelsync -l \$(DISTNAME)_\$(VERSION_SYM) ...
#	cvs tag -F      \$(DISTNAME)_\$(VERSION_SYM) .

maintainer-diff:
	c4 diff     ...@\$(DISTNAME)_\$(VERSION_SYM) 

maintainer-dist: dist tag
	mv \$(DISTVNAME).tar.gz \$(HOME)/src/kits

maintainer-copy:

maintainer-clean: distclean
	-rm README Makefile

";
}

WriteMakefile(
	      DISTNAME  => 'Parse-RandGen',
	      NAME      => 'Parse::RandGen',
	      AUTHOR	=> 'Jeff Dutton <jdutton@cpan.org>',
	      ABSTRACT  => 'Generate random parse data for regexp or BNF grammar',
	      VERSION_FROM  => 'RandGen.pm',
	      PMLIBDIRS => ['lib', 'Parse', 'RandGen',],
	      PREREQ_PM => { 'YAPE::Regex' => 3.02,
			   },
	      'clean'	=> {FILES => qw (test_dir),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

