use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Plack-Middleware-RequestId',
    module_name         => 'Plack::Middleware::RequestId',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/RequestId.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent' => 0,
        'Plack::Builder' => 0,
        'Plack::Test' => 0,
    },
    requires => {
        'perl' => '5.008000',
        'strict' => 0,
        'warnings' => 0,
        'Data::UUID' => 0,
        'Plack::Middleware' => 0,
        'Plack::Util' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-RequestId-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-RequestId',
        bugtracker  => 'http://github.com/bayashi/Plack-Middleware-RequestId/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
