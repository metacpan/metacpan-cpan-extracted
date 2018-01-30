use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME      => 'Object::Realize::Later'
  , VERSION   => '0.21'
  , PREREQ_PM =>
     { Scalar::Util => 0.0
     }
  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Delayed realization of objects'
  , LICENSE   => 'perl'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Object-Realize-Later.git'
              , web  => 'https://github.com/markov2/perl5-Object-Realize-Later'
              }
          }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/object-realize-later/raw
DISTDIR         = ../public_html/object-realize-later/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2001
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE
