use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [ 'Template-Plugin-Text-Widont-*' ],
    build_requires     => {
        'Template'   => '2.07',
        'Test::More' => '0',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    dist_version_from  => 'lib/Template/Plugin/Text/Widont.pm',
    license            => 'perl',
    module_name        => 'Template::Plugin::Text::Widont',
    requires           => {
        'Template::Plugin::Filter' => '0',
        'Text::Widont'             => '0',
    },
);

$builder->create_build_script();
