use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::API::Gett',
    license             => 'perl',
    dist_author         => q{Mark Allen <mrallen1@yahoo.com>},
    dist_version_from   => 'lib/Net/API/Gett.pm',
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'File::Temp' => 0,
        'Test::More'  => 0,
    },
    requires => {
        'perl' => '5.010',
        'LWP::Protocol::https' => 0,
        'Moo'         => '0.009013',
        'Sub::Quote'  => 0,
        'LWP'         => 0,
        'JSON'        => 0,
        'File::Slurp' => 0,
        'Array::Iterator' => 0,
        'MooX::Types::MooseLike' => '0.02',
    },
    add_to_cleanup      => [ 'Net-API-Gett-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/mrallen1/Net-API-Gett.git',
            KeyWords => ["file sharing", "gett", "REST API client"],
        },
    },
);

$builder->create_build_script();
