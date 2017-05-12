use strict;
use Module::Build;

my $build = Module::Build->new(
    license            => 'perl',
    module_name        => 'SQL::ReservedWords',
    requires           => {
        'Sub::Exporter' => 0,
    },
    build_requires     => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    script_files       => [
        'scripts/sqlrw'
    ]
);

$build->create_build_script;
