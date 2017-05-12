use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME	 => 'OODoc'
  , VERSION      => '2.01'
  , PREREQ_PM    =>
    { Test::More              => 0.47
    , File::Slurp             => 9999.12
    , OODoc::Template         => 0.16
    }
  , EXE_FILES    => [ 'bin/oodist' ]

  , AUTHOR       => 'Mark Overmeer'
  , ABSTRACT     => 'Object Oriented Documentation'
  , LICENSE      => 'perl'
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
EXTENDS         = ../OODocTemplate

# for HTML
HTML_OUTPUT	= ../public_html/oodoc/html
HTML_DOCROOT	= /oodoc/html
HTML_PACKAGE	= ../public_html/oodoc/htmlpkg

__POSTAMBLE

