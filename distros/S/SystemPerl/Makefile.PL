# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
all:: README

README: Manual.pod
	-\$(RM_RF) \$@
	pod2text --loose \$< > \$@

dist: distcheck README

install-local: manifypods
	cp -R blib/man*    \$(DIRPROJECT_PREFIX)/man
	cp -R sp_makecheck \$(DIRPROJECT_PREFIX)/bin/sp_makecheck__notfound
	cp systemc-mode.el \$(DIRPROJECT_PREFIX)/site-lisp

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
	echo \"NOTE: Did you try a test without SYSTEMC set?\"

maintainer-clean: distclean
	-rm -rf README Makefile

clean::
	-rm -rf test_dir test_scl
";
}

my $fail;
local $! = undef;
`flex --version`; if ($?) { $fail=1; warn "\n%Error: 'flex' must be installed to build\n"; }
`bison --version`; if ($?) { $fail=1; warn "\n%Error: 'bison' must be installed to build\n"; }
if ($fail) {
    if ($ENV{AUTOMATED_TESTING}) {
	exit(0);
    } else {
	die "%Error: Exiting due to above missing dependencies.\n";
    }
}

WriteMakefile(
	      DISTNAME  => 'SystemPerl',
	      NAME      => 'SystemC::Netlist',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT  => 'SystemC Netlist Utilities and Parsing',
	      VERSION_FROM  => 'Netlist.pm',
	      NO_META	=> 1,
	      PREREQ_PM => {'Pod::Usage' => 1.34,
			    'Verilog::Getopt' => 2.211,
			    'Verilog::Netlist' => 3.200,
			},
	      PMLIBDIRS => [qw( Coverage Netlist Parser)],
	      EXE_FILES => [qw( sp_preproc sp_includer sp_makecheck vcoverage )],
	      'clean'	=> {FILES => qw ( ),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz',
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

if (!$ENV{SYSTEMC} && !$ENV{SYSTEMC_INCLUDE}) {
    warn "-Info: SystemC isn't in the environment, 'make test' will skip tests\n";
}

my $mkv = `make --version`;
if ($? || $mkv !~ /GNU Make/i) {
    warn "-Important: Now type 'gmake MAKE=gmake' as this package requires GNU Make\n";
}
1;
