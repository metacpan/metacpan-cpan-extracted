use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Context::Cacheable',
    license             => 'perl',
    dist_author         => 'Walery Studennikov',
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
