use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Pluggable::Dependency',
    license             => 'mit',
    dist_version_from   => 'lib/Module/Pluggable/Dependency.pm',
    create_makefile_pl  => 'passthrough',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Module::Pluggable'     => '1.9',
        'Algorithm::Dependency' => '1.04',
    },
    add_to_cleanup      => [ 'Module-Pluggable-Dependency-*' ],
);

$builder->create_build_script();
