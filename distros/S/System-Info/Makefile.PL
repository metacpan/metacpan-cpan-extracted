#!/usr/bin/perl

require 5.008003;
use strict;

if ($ENV{PERLBREW_HOME} and $ENV{PERLBREW_HOME} eq "/home/njh/.perlbrew") {
     warn "Your smokers have been blocked because of consistent failures that\n";
     warn " are all caused by the smoking setup and not by module errors. I you\n";
     warn " have fixed that all, please inform the authors, so this block can\n";
     warn " be lifted again.\n";
     exit 0;
     }

use ExtUtils::MakeMaker;

my %wm = (
    NAME         => "System::Info",
    DISTNAME     => "System-Info",
    ABSTRACT     => "Extract system info for reporting",
    AUTHOR       => [ "H.Merijn Brand <h.merijn\@xs4all.nl>",
		      "Abe Timmerman <abeltje\@cpan.org>" ],
    VERSION_FROM => "lib/System/Info.pm",
    macro        => { TARFLAGS => "--format=ustar -c -v -f" },
    );
    $ExtUtils::MakeMaker::VERSION >  6.30 and $wm{LICENSE} = "perl";
    $ExtUtils::MakeMaker::VERSION <  7.10 and $wm{AUTHOR}  = $wm{AUTHOR}[0];
$wm{$ExtUtils::MakeMaker::VERSION >= 6.64 ? "TEST_REQUIRES" : "PREREQ_PM"} = {
    "Test::More"	=> 0.88,
    "Test::NoWarnings"	=> 0,
    };

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble {
    my $valgrind = join " ", qw(
	PERL_DESTRUCT_LEVEL=2 PERL_DL_NONLAZY=1
	    valgrind
		--suppressions=sandbox/perl.supp
		--leak-check=yes
		--leak-resolution=high
		--show-reachable=yes
		--num-callers=50
		--log-fd=3
		$(FULLPERLRUN) "-MExtUtils::Command::MM" "-e"
		    "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"
		    $(TEST_FILES) 3>valgrind.log
		    );

    my $min_vsn = ($] >= 5.010 && -d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover test_cover:',
	'	ccache -C',
	'	cover -test',
	'',
	'leakcheck:',
	"	$valgrind",
	'	-@tail -5 valgrind.log',
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
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	$min_vsn;
    } # postamble
