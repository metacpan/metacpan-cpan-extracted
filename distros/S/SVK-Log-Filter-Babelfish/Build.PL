use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SVK::Log::Filter::Babelfish',
    license             => 'mit',
    dist_version_from   => 'lib/SVK/Log/Filter/Babelfish.pm',
    sign                => 1,
    create_makefile_pl  => 'passthrough',
    requires => {
        'SVK'            => '1.99',
        'WWW::Babelfish' => 0.13,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'SVK-Log-Filter-Babelfish-*' ],
);

$builder->create_build_script();
