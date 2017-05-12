use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::IRC::Plugin::Unicode::UCD',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/IRC/Plugin/Unicode/UCD.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                                  => 1.04,
        'POE::Component::IRC::Plugin::BaseWrap' => 0.001,
        'Unicode::UCD'                          => 0.24,
        'Encode'                                => 2.12,
        perl => 5.006,
    },
    configure_requires => { 'Module::Build' => 0.40 },
    add_to_cleanup      => [ 'POE-Component-IRC-Plugin-Unicode-UCD-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/POE/Component/IRC/Plugin/Unicode/UCD.pm > README');
}

$builder->create_build_script();
