use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Object::Boolean',
    license             => 'perl',
    dist_author         => 'Brian Duggan <bduggan@matatu.org>',
    dist_version_from   => 'lib/Object/Boolean.pm',
    requires            => { 'Sub::Exporter' => 0, 'Class::Data::Inheritable' => 0 },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Object-Boolean-*' ],
    create_makefile_pl => 'traditional'
);

$builder->create_build_script();
