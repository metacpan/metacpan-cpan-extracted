use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::IRC::Plugin::WWW::Google::Time',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/IRC/Plugin/WWW/Google/Time.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'POE'                                       => 0.9999,
        'POE::Component::IRC::Plugin::BasePoCoWrap' => 0.004,
        'POE::Component::WWW::Google::Time'         => 0.0101,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-IRC-Plugin-WWW-Google-Time-*' ],
    create_makefile_pl => 'traditional',
);

if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/POE/Component/IRC/Plugin/WWW/Google/Time.pm > README');
}
$builder->create_build_script();
