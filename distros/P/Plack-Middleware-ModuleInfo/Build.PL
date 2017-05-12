use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Plack-Middleware-ModuleInfo',
    module_name         => 'Plack::Middleware::ModuleInfo',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/ModuleInfo.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Builder' => 0,
        'HTTP::Request::Common' => 0,
        'File::Spec' => 0,
        'Plack::Test' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'strict' => 0,
        'warnings' => 0,
        'Plack::Middleware' => 0,
        'Plack::Util::Accessor' => 0,
        'Net::CIDR::Lite' => 0,
        'Module::Info' => 0,
        'YAML' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-ModuleInfo-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-ModuleInfo',
        bugtracker  => 'http://github.com/bayashi/Plack-Middleware-ModuleInfo/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
