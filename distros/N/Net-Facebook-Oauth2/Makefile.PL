use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Facebook::Oauth2',
    VERSION_FROM      => 'lib/Net/Facebook/Oauth2.pm', # finds $VERSION
    PREREQ_PM         => {
        'LWP::UserAgent'       => 0,
        'LWP::Protocol::https' => 0,
        'URI'                  => 0,
        'Carp'                 => 0,
        'URI::Escape'          => 0,
        'JSON::MaybeXS'        => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'       => 0.88,
        'Test::Exception'  => 0,
        'Test::MockObject' => 0,
        'Test::MockModule' => 0,
        'Plack::Request'   => 0,
        'Plack::Loader'    => 0,
        'Test::Requires'   => 0,
        'Test::TCP'        => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
          ABSTRACT_FROM  => 'lib/Net/Facebook/Oauth2.pm', # retrieve abstract from module
          AUTHOR         => 'Mahmoud A. Mehyar <mamod.mehyar@gmail.com>'
      )
      : ()
    ),
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/mamod/Net-Facebook-Oauth2/issues',
            repository => 'https://github.com/mamod/Net-Facebook-Oauth2',
        },
    },
);
