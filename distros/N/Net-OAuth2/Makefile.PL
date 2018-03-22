
use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'Net::OAuth2'
  , VERSION     => '0.64'
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
  , AUTHOR      => 'Mark Overmeer <markov@cpan.org>'
  , ABSTRACT    => 'OAuth2 authenticating client'
  , LICENSE     => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Net-OAuth2.git'
              , web  => 'https://github.com/markov2/perl5-Net-OAuth2'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }

  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/net-oauth2/raw
DISTDIR         = ../public_html/net-oauth2/source

# for POD
FIRST_YEAR      = 2013
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE

