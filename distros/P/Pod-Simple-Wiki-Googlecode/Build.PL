use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::Simple::Wiki::Googlecode',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Pod/Simple/Wiki/Googlecode.pm',
    build_requires => {
        'Test::More' => 0,
        'Pod::Simple::Wiki' => 0,
    },
    add_to_cleanup      => [ 'Pod-Simple-Wiki-Googlecode-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
