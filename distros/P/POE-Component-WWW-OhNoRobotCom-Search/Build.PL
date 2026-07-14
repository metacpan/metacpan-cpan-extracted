use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::WWW::OhNoRobotCom::Search',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/WWW/OhNoRobotCom/Search.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                                     => 1.04,
        'POE'                                      => 0.9999,
        'WWW::OhNoRobotCom::Search'                => 0.001,
        'POE::Component::NonBlockingWrapper::Base' => 0.001,
    },
    add_to_cleanup      => [ 'POE-Component-WWW-OhNoRobotCom-Search-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
