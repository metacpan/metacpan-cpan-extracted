use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::SRCDS::Queries',
    license             => 'perl',
    dist_author         => 'Masanori Hara <massa.hara at gmail.com>',
    dist_version_from   => 'lib/Net/SRCDS/Queries.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Net-SRCDS-Queries-*' ],
);

$builder->create_build_script();
