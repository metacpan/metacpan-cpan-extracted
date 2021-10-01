
use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'Net::OAuth2'
  , VERSION     => '0.67'
  , PREREQ_PM   =>
      { 'Test::More' => 0,
        'constant' => 0,
        'strict' => 0,
        'warnings' => 0,
        'Carp' => 0,
        'Encode' => 0,
        'Scalar::Util' => 0,
        'MIME::Base64' => 0,
        'URI' => '0',
        'JSON::MaybeXS' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request' => 0,
        'HTTP::Response' => 0,
        'HTTP::Status' => 0,

# optional
#         'Test::Mock::LWP::Dispatch' => 0
      }
  , AUTHOR      => 'Thomas Uhle <uhle@cpan.org>'
  , ABSTRACT    => 'OAuth2 authenticating client'
  , LICENSE     => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { homepage   => 'https://search.cpan.org/~uhle/Net-OAuth2/',
            repository => {
                type   => 'git',
                url    => 'https://gitlab.com/uhle/perl-net-oauth2.git',
                web    => 'https://gitlab.com/uhle/perl-net-oauth2'
            },
            bugtracker => {
                web    => 'https://gitlab.com/uhle/perl-net-oauth2/-/issues',
            },
            license  => 'http://dev.perl.org/licenses/',
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
EMAIL           = uhle@cpan.org
WEBSITE         = https://search.cpan.org/~uhle/Net-OAuth2/
__POSTAMBLE

