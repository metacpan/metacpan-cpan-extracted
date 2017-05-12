use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::SMTP::Bulk',
    license             => 'perl',
    dist_author         => q{KnowZero},
    dist_version_from   => 'lib/Net/SMTP/Bulk.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'AnyEvent'              => 1,
        'Encode'              => 1,
    },
    recommends => {
        'Coro'              => 1,
        'IO::Socket::SSL'              => 1,
        'Authen::SASL'              => 1,
        'MIME::Base64'              => 1,
    },
    add_to_cleanup     => [ 'Net-SMTP-Bulk-*' ],
    create_readme => 1,
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
