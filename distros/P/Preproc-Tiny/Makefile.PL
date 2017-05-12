use 5.010;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Preproc::Tiny',
    VERSION_FROM      => 'lib/Preproc/Tiny.pm', 
    PREREQ_PM         => {}, 
	BUILD_REQUIRES    => {
		'Test::More'		=> 0,
		'Capture::Tiny'		=> 0,
		'Path::Tiny'		=> 0,
		'Test::Differences'	=> 0,
	},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Preproc/Tiny.pm',
       AUTHOR         => 'Paulo Custodio, <pscust@cpan.org>',
	   META_MERGE => {
				'meta-spec' => { version => 2 },
				resources => {
					repository  => {
						type => 'git',
						url  => 'https://github.com/pauloscustodio/perl-Preproc-Tiny.git',
						web  => 'https://github.com/pauloscustodio/perl-Preproc-Tiny',
					},
				},
	  }) : ()),
);

sub MY::postamble {
	return q{

pure_all :: $(INST_BIN)$(DFSEP)pp.pl

$(INST_BIN)$(DFSEP)pp.pl : \
				lib$(DFSEP)Preproc$(DFSEP)Tiny.pm \
				$(FIRST_MAKEFILE)
	$(PERLRUNINST) -MExtUtils::Command -e cp lib$(DFSEP)Preproc$(DFSEP)Tiny.pm $(INST_BIN)$(DFSEP)pp.pl
};
}
