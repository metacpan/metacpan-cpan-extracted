
use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'Net::OAuth2'
  , VERSION     => '0.63'
  , PREREQ_PM   =>
     { Test::More => 0
     , YAML => 0
     , URI  => '0'
     , JSON => '0'
     , LWP::UserAgent => '0'
     , Scalar::Util   => 0
     , HTTP::Request  => 0
     , HTTP::Status   => 0

# optional
#    , Test::Mock::LWP::Dispatch => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'OAuth version 2 client'
  , LICENSE     => 'perl'
  , EXE_FILES   => []
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/net-oauth2/raw
DISTDIR         = ../public_html/net-oauth2/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE

