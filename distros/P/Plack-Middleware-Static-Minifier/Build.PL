use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::Middleware::Static::Minifier',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/Static/Minifier.pm',
    build_requires      => {
        'Test::More' => 0.88,
        'HTTP::Request::Common' => 0,
        'Cwd' => 0,
    },
    requires => {
        'perl' => '5.8.7',
        'parent' => 0,
        'Plack' => 0.9958,
        'Plack::Util::Accessor' => 0,
        'CSS::Minifier::XS' => 0.09,
        'JavaScript::Minifier::XS' => 0,
        'Digest::MD5' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-Static-Minifier-*' ],
    meta_merge     => {
      resources => {
        repository  => 'git://github.com/bayashi/Plack-Middleware-Static-Minifier.git'
      }
    },
);

$builder->create_build_script();
