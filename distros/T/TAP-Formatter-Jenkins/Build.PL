use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TAP::Formatter::Jenkins',
    license             => 'perl',
    dist_author         => q{Evgeniy Vostrov <vostrov.e@gmail.com>},
    dist_version_from   => 'lib/TAP/Formatter/Jenkins.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'                => 0,
        'Test::Spec'                => 0,
        'Test::Spec::Mocks'         => 0,
        'Test::MockObject::Extends' => 0,
        'TAP::Harness'              => 0,
        'File::Slurp'               => 0,
        'File::Temp'                => 0,
    },
    requires => {
        'Moose'            => 2.0000,
        'MooseX::NonMoose' => 0.20,
        'TAP::Harness'     => 3.20,
        'Encode'           => 2.42,
        'TAP::Parser::YAMLish::Writer' => 0,
    },
    add_to_cleanup     => [ 'TAP-Formatter-Jenkins-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
