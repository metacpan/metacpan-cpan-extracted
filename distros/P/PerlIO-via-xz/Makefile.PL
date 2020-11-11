#!/usr/bin/perl

# Copyright 2020-2020 H.Merijn Brand

require 5.012000;
use strict;

if ($ENV{PERLBREW_HOME} and $ENV{PERLBREW_HOME} eq "/home/njh/.perlbrew") {
     warn "Your smokers have been blocked because of consistent failures that\n";
     warn " are all caused by the smoking setup and not by module errors.  If\n";
     warn " you have fixed that all, please inform the authors, so this block\n";
     warn " can be lifted again.\n";
     exit 0;
     }

use ExtUtils::MakeMaker;

my %wm = (
    NAME         => "PerlIO::via::xz",
    DISTNAME     => "PerlIO-via-xz",
    ABSTRACT     => "PerlIO layer for xz (de)compression",
    AUTHOR       => 'H.Merijn Brand <hmbrand@cpan.org>',
    VERSION_FROM => "lib/PerlIO/via/xz.pm",
    LICENSE	 => "perl",
    PREREQ_PM	 => { "Carp"			=> 0,
		      "PerlIO"			=> 0,
		      "IO::Compress::Xz"	=> 2.096,
		      "IO::Uncompress::UnXz"	=> 2.096,
		      "Test::More"		=> 0,
		      },
    clean        => { FILES => join " ", qw(
			 cover_db
			 valgrind.log
			 pod2htmd.tmp
			 MYMETA.json
			 MYMETA.yml
			 )
		      },
    macro        => { TARFLAGS => "--format=ustar -c -v -f",
		      },
    );

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble {
    my $make_sep = $^O eq "VMS" ? "," : "";
    my $min_vsn = (-d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover $make_sep test_cover:',
	'	cover -test',
	'',
	'leaktest:',
	q{	sandbox/leaktest $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'	ls -l */META.yml',
	'',
	'tgzdist:	doc checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'doc docs::		doc/PerlIO-via-xz.md doc/PerlIO-via-xz.html doc/PerlIO-via-xz.man',
	'	-@rm -f pod2html.tmp',
	'doc/PerlIO-via-xz.md:		lib/PerlIO/via/xz.pm',
	'	pod2markdown  < $? > $@',
	'doc/PerlIO-via-xz.html:	lib/PerlIO/via/xz.pm',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/PerlIO-via-xz.3:		lib/PerlIO/via/xz.pm',
	'	pod2man       < $? > $@',
	'doc/PerlIO-via-xz.man:	doc/PerlIO-via-xz.3',
	'	nroff -mandoc < $? > $@',
	'',
	$min_vsn;
    } # postamble
