use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'POSIX::Util'
  , VERSION     => '0.10'
  , PREREQ_PM   =>
     { Test::More     => 0.47
     , POSIX::1003    => 0.13
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Useful helpers on top of POSIX::1003'
  , LICENSE     => 'perl'
  , PL_FILES    => {}
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/posix-util/raw
DISTDIR         = ../public_html/posix-util/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2012
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE

