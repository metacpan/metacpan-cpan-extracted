use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::Archive::Any',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/Archive/Any.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                   => 0,
        'POE'                    => 0,
        'POE::Wheel::Run'        => 0,
        'POE::Filter::Reference' => 0,
        'POE::Filter::Line'      => 0,
        'Archive::Any'           => 0,
        perl                     => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-Archive-Any-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
