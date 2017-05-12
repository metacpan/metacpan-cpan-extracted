use ExtUtils::MakeMaker;
use ExtUtils::F77;

WriteMakefile(
	      AUTHOR         => 'Ari Jolma https://github.com/ajolma',
              BUILD_REQUIRES => {
                                  'ExtUtils::F77' => '0',
                                },
	      PREREQ_PM      => {
                                },
	      NAME	     => 'Statistics::Lmoments',
	      VERSION_FROM   => 'Lmoments.pm',
              ABSTRACT_FROM  => 'Lmoments.pm',
	      LIBS	     => [" -L/usr/lib " . 'ExtUtils::F77'->runtime],
	      DEFINE	     => '',
	      INC	     => '',
	      MYEXTLIB       => 'lmoments/libclmoments$(LIB_EXT) lmoments/liblmoments$(LIB_EXT) -lc',
              LICENSE        => 'perl_5',
              META_MERGE     => {
                  'meta-spec' => { version => 2 },
                  resources => {
                      repository  => {
                          type => 'git',
                          web  => 'https://github.com/ajolma/Statistics-Lmoments',
                          url  => 'https://github.com/ajolma/Statistics-Lmoments.git',
                      },
                  },
              }
	      );

sub MY::postamble {
'
$(MYEXTLIB): lmoments/Makefile
	cd lmoments && $(MAKE) $(PASTHRU)
';
}
