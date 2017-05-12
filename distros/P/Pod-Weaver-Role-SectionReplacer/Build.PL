use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::Weaver::Role::SectionReplacer',
    license             => 'perl',
    dist_author         => q{Sam Graham <libpod-weaver-role-sectionreplacer-perl@illusori.co.uk>},
    dist_version_from   => 'lib/Pod/Weaver/Role/SectionReplacer.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires       => {
        'Moose'          => 0,
        'Moose::Autobox' => '0.11',
        'Pod::Elemental' => '0.101620',
        'Pod::Weaver'    => 0,
    },
    meta_merge => {
        'resources' => {
            'repository' => 'http://github.com/illusori/Perl-Pod-Weaver-Role-SectionReplacer',
            },
        },
    create_readme => 1,
    sign => 1,
    dynamic_config => 0,
);

$builder->create_build_script();
