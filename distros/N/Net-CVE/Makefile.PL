use strict;

require 5.014002;

use ExtUtils::MakeMaker;
use File::Copy;

sub link_or_copy {
    my ($source, $dest) = @_;

    link ($source, $dest) or copy ($source, $dest);
    } # link_or_copy

my @exe;
unless (exists $ENV{AUTOMATED_TESTING} and $ENV{AUTOMATED_TESTING} == 1) {
    for ( [ "cve.pl",	"CLI to Net::CVE"	],
	  ) {
	prompt ("Do you want to install $_->[0]\t$_->[1] ?", "y") =~ m/[Yy]/ and
	    push @exe => "scripts/$_->[0]";
	}
    }
my %wm = (
    NAME         => "Net::CVE",
    DISTNAME     => "Net-CVE",
    ABSTRACT     => "Fetch CVE info from cve.org",
    AUTHOR       => "H.Merijn Brand <hmbrand\@cpan.org>",
    VERSION_FROM => "lib/Net/CVE.pm",
    LICENSE      => "perl",
    EXE_FILES    => [ @exe ],
    PREREQ_FATAL => 0,
    PREREQ_PM    => {
	# Core modules
	"Carp"				=> 0,
	"HTTP::Tiny"			=> 0.009,
	"JSON::MaybeXS"			=> 1.004005,
	"List::Util"			=> 0,

	# For testing
	"Test::More"			=> 0.90,
	"Test::Warnings"		=> 0,
	},
    macro        => { TARFLAGS   => "--format=ustar -c -v -f", },
    );

if ($ENV{EXTENDED_TESTING}) { # for CpanCover and masochists
    # Backend parsers, all optional
    #$wm{PREREQ_PM}{"Net::OSV"}		= "0.0.1";
    #$wm{PREREQ_PM}{"Net::NSD"}		= "0.0.1";
    }

my $rv = WriteMakefile (%wm);

# perlcriticrc uses Config::Tiny, which does not support nesting
if (-f ".perlcriticrc" && -s "$ENV{HOME}/.perlcriticrc") {
    open my $fh, ">", ".perlcriticrc";
    print $fh do {
	local (@ARGV, $/) = ("$ENV{HOME}/.perlcriticrc");
	<> =~ s{^hard_max = \K\d+$}{150}rm };
    print $fh join "\n" => "",
	"[-Community::EmptyReturn]",	#
	"[-Community::Wantarray]",	#
	"";
    close $fh;
    }

package MY;

sub postamble {
    my @pc = -f ".perlcriticrc" ? ("\tperlcritic -1 lib/Net/CVE.pm") : ();
    -d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1 and push @pc,
	'',
	'test::',
	'	-@env TEST_FILES="xt/*.t" make -e test_dynamic';
    join "\n" =>
	'cover test_cover:',
	'	ccache -C',
	'	cover -test',
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell lib',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'	ls -l */META.yml',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'doc docs:		doc/Net-CVE.md doc/Net-CVE.html doc/Net-CVE.man',
	'	-@rm -f pod2html.tmp',
	'doc/Net-CVE.md:		lib/Net/CVE.pm',
	'	pod2markdown  < $? > $@',
	'doc/Net-CVE.html:		lib/Net/CVE.pm',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/Net-CVE.3:		lib/Net/CVE.pm',
	'	pod2man       < $? > $@',
	'doc/Net-CVE.man:	doc/Net-CVE.3',
	'	nroff -mandoc < $? > $@',
	@pc,
	'';
    } # postamble

1;
