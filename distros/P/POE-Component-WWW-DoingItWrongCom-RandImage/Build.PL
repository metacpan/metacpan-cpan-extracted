use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::WWW::DoingItWrongCom::RandImage',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/WWW/DoingItWrongCom/RandImage.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                            => 1.04,
        'POE'                             => 0.9999,
        'POE::Filter::Reference'          => 1.2187,
        'POE::Filter::Line'               => 1.1920,
        'POE::Wheel::Run'                 => 1.2179,
        'WWW::DoingItWrongCom::RandImage' => 0.01,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-WWW-DoingItWrongCom-RandImage-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/POE/Component/WWW/DoingItWrongCom/RandImage.pm > README');
}

$builder->create_build_script();
