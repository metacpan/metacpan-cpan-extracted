#!/usr/bin/perl

# Copyright Toolchain Gang / CPAN Security group (c) 2023-2025 H.Merijn Brand

require 5.014000;
use strict;

use ExtUtils::MakeMaker;

my @exe;
unless (exists $ENV{AUTOMATED_TESTING} and $ENV{AUTOMATED_TESTING} == 1) {
    for ( [ "cpan-cve.pl", "to check dist folder or file against known CVE's" ],
	  ) {
	prompt ("Do you want to install '$_->[0]'\n   $_->[1] ?", "y") =~ m/[Yy]/ and
	    push @exe, "scripts/$_->[0]";
	}
    }
my %wm = (
    NAME		=> "Test::CVE",
    DISTNAME		=> "Test-CVE",
    ABSTRACT		=> "Test current release against CVE's",
    AUTHOR		=> "H.Merijn Brand <hmbrand\@cpan.org>",
    VERSION_FROM	=> "lib/Test/CVE.pm",
    EXE_FILES		=> \@exe,
    LICENSE		=> "perl",
    PREREQ_PM		=> { "version"			=> 0,
			     "HTTP::Tiny"		=> 0,
			     "Text::Wrap"		=> 0,
			     "YAML::PP"			=> 0,
			     "JSON::MaybeXS"		=> 0,
			     "Module::CoreList"		=> 0,
			     "Test::Builder::Module"	=> 0,
			     },
    MIN_PERL_VERSION	=> "5.014",
    clean		=> { FILES => join " ", qw(
				 CVE.c.gcov CVE.gcda CVE.gcno
				 MYMETA.json MYMETA.yml
				 cover_db
				 pod2htmd.tmp
				 )
			     },
    macro		=> { TARFLAGS   => "--format=ustar -c -v -f",
			     },
    META_MERGE		=> {
	"meta-spec"	=> { version => 2 },
	"resources"	=> {
	    repository	=> {
		"type"	=> "git",
		"url"	=> "https://github.com/CPAN-Security/Test-CVE.git",
		"web"	=> "https://github.com/CPAN-Security/Test-CVE",
		},
	    bugtracker	=> {
		"web"	=> "https://github.com/CPAN-Security/Test-CVE/issues",
		},
	    },
	},
    );

my $rv = WriteMakefile (%wm);

# perlcriticrc uses Config::Tiny, which does not support nesting
-f ".perlcriticrc" && -s "$ENV{HOME}/.perlcriticrc" and eval {
    open my $fh, ">", ".perlcriticrc";

    require Config::Tiny;
    my $cnf = Config::Tiny->read ("$ENV{HOME}/.perlcriticrc");
    for ("BuiltinFunctions::ProhibitBooleanGrep",
	 "BuiltinFunctions::ProhibitStringyEval",	# version check
	 "Community::EmptyReturn",
	 "Community::WhileDiamondDefaultAssignment",
	 "ControlStructures::ProhibitPostfixControls",	# postfix if in diag
	 "Documentation::ProhibitDuplicateHeadings",	# 3:cve / 4:cve
	 "ErrorHandling::RequireCarping",		# for autodie
         "Freenode::PackageMatchesFilename",		# XS
	 "Subroutines::ProhibitBuiltinHomonyms",	# eof, say
	 "Variables::RequireLocalizedPunctuationVars",	# *_, %_
	 ) {
	delete $cnf->{$_};
	$cnf->{"-$_"} = {};
	}
    $cnf->{"Compatibility::PodMinimumVersion"}{above_version} = "5.014";
    $cnf->write (".perlcriticrc");
    };

1;

package MY;

sub postamble {
    my $make_sep = $^O eq "VMS" ? "," : "";
    my $min_vsn  = (-d "xt" && -d "sandbox" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover $make_sep test_cover:',
	'	ccache -C',
	'	-@rm -f *.gc??',
	'	cover -test',
	"	cover -report html_basic",
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
	'',
	'tgzdist:	$(DISTVNAME).tar.gz distcheck',
	'	-@perl -Mblib scripts/cpan-cve.pl .',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'	-@echo "Consider running sandbox/used-by.pl now"',
	'',
	'test_used:	test',
	'	prove -vwb sandbox/used-by.pl',
	'',
	'.PHONY:	doc',
	'doc docs::	doc/Test-CVE.md',
	'doc/Test-CVE.md:	lib/Test/CVE.pm',
	'	perl doc/make-doc.pl',
	'',
	$min_vsn;
    } # postamble

# vim: noet
