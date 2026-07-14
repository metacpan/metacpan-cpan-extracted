use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::WWW::XKCD::AsText',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/WWW/XKCD/AsText.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                   => 1.04,
        'WWW::XKCD::AsText'      => 0.001,
        'POE'                    => 0.9999,
        'POE::Filter::Line'      => 1.2222,
        'POE::Filter::Reference' => 1.2220,
        'POE::Wheel::Run'        => 1.2222,
    },
    add_to_cleanup      => [ 'POE-Component-WWW-XKCD-AsText-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
