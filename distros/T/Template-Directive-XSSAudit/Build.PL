#!perl
use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name        => 'Template::Directive::XSSAudit',
    license            => 'perl',
    dist_abstract      => 'TT2 output filtering lint testing',
    dist_author        => 'David Bartle <dbartle@mediatemple.net>',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    requires           => {
        'Carp'                => 0,
        'FindBin'             => 0,
        'Getopt::Long'        => 0,
        'Pod::Usage'          => 0,
        'Template'            => 0,
        'Template::Directive' => 0,
    },
    meta_merge => {
        'resources' => {
            'homepage' => 'http://github.com/captin411/template-directive-xssaudit',
            'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Template-Directive-XSSAudit',
            'repository' => 'http://github.com/captin411/template-directive-xssaudit',
        },
    },
    build_requires => {
        'List::Util'          => 0,
        'Test::More'          => 0,
        'Template'            => 0,
    },
    script_files => {
        'script/ttxsscheck' => 'script/ttxsscheck',
    },
)->create_build_script;

