use ExtUtils::MakeMaker;

use 5.10.0;

WriteMakefile
  ( NAME        => 'POSIX::1003'
  , VERSION_FROM => 'lib/POSIX/1003/Module.pm'
  , PREREQ_PM   =>
     { Test::More     => 0.47
     , POSIX          => 0
     , XSLoader       => 0
     , File::Spec     => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'POSIX::1003, alternative for POSIX in core'
  , INC         => '-I.'
  , realclean   => {FILES => '*.c'}
  , LICENSE     => 'perl_5'

  , META_MERGE  =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-POSIX-1003.git'
              , web  => 'https://github.com/markov2/perl5-POSIX-1003'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }


  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

1003.c: system.c

system.c: lists.PL
	$(NOECHO) $(ECHO) "*** autodetect available symbols"
	$(FULLPERL) lists.PL

linkext:: $(MAN3PODS)
	$(NOECHO) $(ECHO) "*** collect all defined symbols"
	$(FULLPERL) symbols.PL
	$(NOECHO) $(ECHO) "*** adding values examples to manuals"
	$(FULLPERL) manuals.PL $(MAN3PODS)

# for DIST
RAWDIR          = ../public_html/posix-1003/raw
DISTDIR         = ../public_html/posix-1003/source

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/CPAN
__POSTAMBLE

