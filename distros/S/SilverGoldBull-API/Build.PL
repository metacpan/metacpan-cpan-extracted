use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SilverGoldBull::API',
    license             => 'perl',
    dist_author         => q{Denis Boyun <denis.boyun@gmail.com>},
    dist_version_from   => 'lib/SilverGoldBull/API.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP::UserAgent' => 6.15,
        'HTTP::Headers' => 6.11,
        'HTTP::Request' => 6.11,
        'URI' =>  1.71,
        'JSON::XS' => 3.02,
        'Mouse' => 0,
        'IO::Socket::SSL' => 2.039,
        'Test::Deep' => 1.124,
    },
    add_to_cleanup     => [ 'SilverGoldBull-API-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
