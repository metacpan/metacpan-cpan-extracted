use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::IRC::Plugin::WWW::XKCD::AsText',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/IRC/Plugin/WWW/XKCD/AsText.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                              => 1.04,
        'POE'                               => 0.9999,
        'POE::Component::WWW::XKCD::AsText' => 0.001,
        'POE::Component::IRC::Plugin'       => 0.10,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-IRC-Plugin-WWW-XKCD-AsText-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/POE/Component/IRC/Plugin/WWW/XKCD/AsText.pm > README');
}

$builder->create_build_script();
