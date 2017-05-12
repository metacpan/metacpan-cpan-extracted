use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile
 ( NAME	      => 'OODoc::Template'
 , VERSION    => 0.16
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Simple template system'
 , PREREQ_PM  =>
    { Test::More   => 0.47
    , Test::Pod    => 1.00
    , Log::Report  => 0.992
    }
 , LICENSE    => 'perl'
 );

sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/oodoc-template/raw
DISTDIR         = ../public_html/oodoc-template/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2003,2007
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/oodoc-template/
__POSTAMBLE
