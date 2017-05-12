use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name    => 'Template::Plugin::StringDump',
    license        => 'perl',
    create_license => 1,
    create_readme  => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::More' => 0.41,  # diag()
    },
    requires => {
        'perl'         => '5.6.0',  # our()
        'parent'       => 0,
        'String::Dump' => 0.08,  # dump_codes
        'Template'     => 2.07,  # Template::Plugin::Filter
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/template-plugin-stringdump-pm5.git',
            homepage   => 'https://github.com/patch/template-plugin-stringdump-pm5',
            bugtracker => 'https://github.com/patch/template-plugin-stringdump-pm5/issues',
        },
    },
);

$builder->create_build_script;
