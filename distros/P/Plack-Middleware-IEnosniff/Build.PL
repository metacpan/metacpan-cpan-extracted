use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::Middleware::IEnosniff',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/IEnosniff.pm',
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Test' => 0,
        'Plack::Builder' => 0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Carp' => 0,
        'Plack::Middleware' => 0,
        'Plack::Util' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-IEnosniff-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-IEnosniff'
      }
    },
);

$builder->create_build_script();
