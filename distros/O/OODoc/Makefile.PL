use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME	  => 'OODoc'
  , VERSION   => '2.02'
  , PREREQ_PM =>
    { Test::More              => 0.47
    , File::Slurp             => 9999.12
    , OODoc::Template         => 0.16
    }
  , EXE_FILES    => [ 'bin/oodist' ]

  , AUTHOR       => 'Mark Overmeer'
  , ABSTRACT     => 'Object Oriented Documentation'
  , LICENSE      => 'perl_5'
  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-OODoc.git'
              , web  => 'https://github.com/markov2/perl5-OODoc'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR		= ../public_html/oodoc/raw
DISTDIR		= ../public_html/oodoc/source
LICENSE		= artistic

# for POD
FIRST_YEAR      = 2003
EMAIL           = oodoc@overmeer.net
WEBSITE         = http://perl.overmeer.net/oodoc/
EXTENDS         = ../OODoc-Template

# for HTML
HTML_OUTPUT	= ../public_html/oodoc/html
HTML_DOCROOT	= /oodoc/html
HTML_PACKAGE	= ../public_html/oodoc/htmlpkg

__POSTAMBLE

