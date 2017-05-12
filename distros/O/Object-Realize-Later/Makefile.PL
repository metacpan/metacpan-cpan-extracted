use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME      => 'Object::Realize::Later'
  , VERSION   => '0.19'
  , PREREQ_PM =>
     { Scalar::Util => 0.0
     }
  , AUTHOR    => 'Mark Overmeer <perl@overmeer.net>'
  , ABSTRACT  => 'Delayed realization of objects'
  , LICENSE   => 'perl'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/orl/raw
DISTDIR         = ../public_html/orl/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2001
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/orl/

__POSTAMBLE
