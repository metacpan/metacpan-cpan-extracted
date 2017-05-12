use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Template::Plugin::LanguageName',
    license => 'perl',
    dist_author => [
        'Nicolas Steenlant <nicolas.steenlant@ugent.be>'
    ],
    dist_version_from => 'lib/Template/Plugin/LanguageName.pm',
    build_requires => {
        'Software::License' => 0,
        'Test::Exception' => 0,
        'Test::More' => 0,
    },
    requires => {
        'parent' => 0,
        'Locale::Codes::Language' => '3.18',
        'Template' => '2.22',
    },
    add_to_cleanup => [qw(
        Template-Plugin-LanguageName-*
    )],
    create_makefile_pl => 'traditional',
    create_license => 1,
);

$builder->create_build_script;

