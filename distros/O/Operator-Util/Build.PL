use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name    => 'Operator::Util',
    license        => 'perl',
    create_license => 1,
    create_readme  => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::More' => 0.40,
    },
    requires => {
        'perl'            => '5.6.0',
        'parent'          => 0,
        'List::MoreUtils' => 0.09,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/operator-util-pm5.git',
            homepage   => 'http://github.com/patch/operator-util-pm5',
            bugtracker => 'http://github.com/patch/operator-util-pm5/issues',
        },
    },
);

$builder->create_build_script;
