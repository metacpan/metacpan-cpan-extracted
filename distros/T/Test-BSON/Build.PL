use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name    => 'Test::BSON',
    license        => 'perl',
    create_license => 1,
    create_readme  => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::More'   => 0.82,  # note()
        'Test::Tester' => 0.107,
    },
    requires => {
        'perl'              => '5.6.0',
        'parent'            => 0,
        'BSON'              => 0,
        'Test::Differences' => 0.47,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/test-bson-pm5.git',
            homepage   => 'http://github.com/patch/test-bson-pm5',
            bugtracker => 'http://github.com/patch/test-bson-pm5/issues',
        },
    },
);

$builder->create_build_script();
