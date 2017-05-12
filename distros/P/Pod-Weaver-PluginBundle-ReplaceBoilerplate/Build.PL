use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::Weaver::PluginBundle::ReplaceBoilerplate',
    license             => 'perl',
    dist_author         => q{Sam Graham <libpod-weaver-pluginbundle-replaceboilerplate-perl@illusori.co.uk>},
    dist_version_from   => 'lib/Pod/Weaver/PluginBundle/ReplaceBoilerplate.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Pod-Weaver-PluginBundle-ReplaceBoilerplate-*' ],
    requires       => {
        'Moose'          => 0,
        'Moose::Autobox' => '0.11',
        'Pod::Elemental' => '0.101620',
        'Pod::Weaver'    => '3.101630',
        'Pod::Weaver::Role::SectionReplacer' => 0,
        'Software::License' => 0,
    },
    meta_merge => {
        'resources' => {
            'repository' => 'http://github.com/illusori/Perl-Pod-Weaver-PluginBundle-ReplaceBoilerplate',
            },
        },
    create_readme => 1,
    sign => 1,
    dynamic_config => 0,
);

$builder->create_build_script();
