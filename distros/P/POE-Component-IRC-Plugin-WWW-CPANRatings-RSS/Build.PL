use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::IRC::Plugin::WWW::CPANRatings::RSS',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/IRC/Plugin/WWW/CPANRatings/RSS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'POE'                                   => 0.9999,
        'POE::Component::WWW::CPANRatings::RSS' => 0.0101,
        'POE::Component::IRC::Plugin'           => 0.10,
        'utf8'                                  => 1.06,
        perl                                    => 5.008,
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-IRC-Plugin-WWW-CPANRatings-RSS-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/POE/Component/IRC/Plugin/WWW/CPANRatings/RSS.pm > README');
}
$builder->create_build_script();
