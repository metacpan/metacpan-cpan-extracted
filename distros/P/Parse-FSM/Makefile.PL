#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Parse::FSM',
    VERSION_FROM        => 'lib/Parse/FSM.pm',
    DISTNAME            => 'Parse-FSM',
    ($] >= 5.005 ?       ## Add these new keywords supported since 5.005
        (
            ABSTRACT_FROM  => 'lib/Parse/FSM.pm',
            AUTHOR         => 'Paulo Custodio <pscust@cpan.org>',
        ) : ()),
    PREREQ_PM => {
		'Capture::Tiny'			=> 0.10,
		'Class::XSAccessor'		=> 1.11,
		'Data::Dump'			=> 1.19,
		'File::Slurp'			=> 9999.15,
		'File::Spec'			=> 3.33,
		'File::Temp'			=> 0.22,
        'Test::More'            => 0.96,		# needs done_testing()
		'Text::Balanced'		=> 2.02,
		'Text::Template'		=> 1.45,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.010)
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'perl_5_16') : ()),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'git://github.com/pauloscustodio/perl-Parse-FSM.git',
                    web  => 'https://github.com/pauloscustodio/perl-Parse-FSM',
                },
            },
          })
    ),

    clean               => { FILES => [	'Parse-FSM-*',
										'Parser.pm',
										'*.tmp',
										'*.bak',
										'~tmpfile.*',
									  ] },
);

sub MY::postamble {
	return q{

pure_all :: $(INST_LIB)$(DFSEP)Parse$(DFSEP)FSM$(DFSEP)Parser.pm

$(INST_LIB)$(DFSEP)Parse$(DFSEP)FSM$(DFSEP)Parser.pm : \
				tools$(DFSEP)build_parser.pl \
				lib$(DFSEP)Parse$(DFSEP)FSM.pm \
				lib$(DFSEP)Parse$(DFSEP)FSM$(DFSEP)Driver.pm \
				$(FIRST_MAKEFILE)
	$(PERLRUNINST) tools$(DFSEP)build_parser.pl Parse::FSM::Parser $(INST_LIB)$(DFSEP)Parse$(DFSEP)FSM$(DFSEP)Parser.pm
};
}
