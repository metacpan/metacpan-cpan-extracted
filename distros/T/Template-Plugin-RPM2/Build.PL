use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::RPM2',
    license             => 'perl',
    dist_author         => 'Dave Cross <dave@mag-sol.com>',
    dist_version_from   => 'lib/Template/Plugin/RPM2.pm',
    build_requires => {
        'Test::More' => 0,
        'Template'   => 2.0,
        'RPM2'       => 0,
    },
    requires => {
        'Test::More' => 0,
        'Template'   => 2.0,
        'RPM2'       => 0,
    },
    add_to_cleanup      => [ 'Template-Plugin-RPM2-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/davorg/template-plugin-rpm2.git',
                web  => 'https://github.com/davorg/template-plugin-rpm2',
            },
            bugtracker => {
                web  => 'https://github.com/davorg/template-plugin-rpm2/issues',
            },
        },
    },
);

$builder->create_build_script();
