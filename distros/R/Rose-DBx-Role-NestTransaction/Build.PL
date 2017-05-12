use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Rose::DBx::Role::NestTransaction',
    license             => 'perl',
    dist_abstract       => 'Nested transactions support for Rose::DB',
    dist_author         => q{Viktor Turskyi <koorchik@cpan.org>},
    dist_version_from   => 'lib/Rose/DBx/Role/NestTransaction.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'       => 5.006,
        'Role::Tiny' => 0,
        'Class::Method::Modifiers' => 0,
    },
    add_to_cleanup     => [ 'Rose-DBx-Role-NestTransaction-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
