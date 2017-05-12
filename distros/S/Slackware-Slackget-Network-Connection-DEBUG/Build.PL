use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Slackware::Slackget::Network::Connection::DEBUG',
    license             => 'perl',
    dist_author         => 'DUPUIS Arnaud <a.dupuis@infinityperl.org>',
    dist_version_from   => 'lib/Slackware/Slackget/Network/Connection/DEBUG.pm',
    build_requires => {
        'Test::More' => 0,
        'Slackware::Slackget' => 0.14,
    },
    add_to_cleanup      => [ 'Slackware-Slackget-Network-Connection-DEBUG-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
