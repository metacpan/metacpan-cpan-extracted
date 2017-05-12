use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::Middleware::Debug::LazyLoadModules',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/Debug/LazyLoadModules.pm',
    build_requires      => {
        'Test::More' => 0.88,
        'Plack' => 0,
        'HTTP::Request::Common' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Plack::Middleware::Debug' => 0,
        'parent' => 0,
        'Carp' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-Debug-LazyLoadModules-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-Debug-LazyLoadModules'
      }
    },
);

$builder->create_build_script();
