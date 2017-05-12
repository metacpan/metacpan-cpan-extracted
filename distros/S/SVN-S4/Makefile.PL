# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2006-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm -rf \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

clean::
	-rm -rf test_dir

dist: maintainer-copy distcheck README

## Maintainer use:
preexist:
	svnorcvs nexists \$(DISTNAME)_\$(VERSION_SYM)
	test -s README

tag:
	svnorcvs tag  \$(DISTNAME)_\$(VERSION_SYM)

maintainer-diff:
	svnorcvs diff \$(DISTNAME)_\$(VERSION_SYM)

maintainer-dist: preexist dist tag
	svnorcvs release \$(DISTVNAME).tar.gz

maintainer-copy:

maintainer-clean: distclean
	-rm -rf README Makefile MANIFEST.bak \$(MAKEFILE_OLD)
";
}

{
    local $! = undef;
    my $ver = `svn --version`;
    if ($? || !$ver) {
	warn "\n%Error: 'svn' must be installed to be useful\n";
	if ($ENV{AUTOMATED_TESTING}) {
	    exit(0);
	} else {
	    die "%Error: Exiting due to above missing dependencies.\n";
	}
    }
    $ver =~ s/\n.*$//omg;
    print "Installed subversion: $ver\n";
}

## Remember to upgrade version number!
WriteMakefile(
	      DISTNAME	=> 'SVN-S4',
	      NAME	=> 'SVN::S4',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT_FROM => 'lib/SVN/S4.pm',
	      VERSION_FROM  => 'lib/SVN/S4.pm',
	      NO_META	=> 1,
	      PREREQ_PM => {'SVN::Client' => 0,
			    'Config::Tiny' => 0,
			    'DBD::SQLite' => 0,
			    'Digest::MD5' => 0,
			    'IO::AIO' => 0,
			    'MIME::Base64' => 0,
			    'Test::More' => 0,
			},
	      EXE_FILES	=> [qw( s4 )],
	      'clean'	=> {FILES => qw(test_store test_dir), },
	      'dist'	=> {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz',
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

