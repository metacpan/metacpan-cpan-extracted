use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'PostScript::LabelSheet',
    license             => 'perl',
    dist_author         => q{Cédric Bouvier <cbouvi@cpan.org>},
    dist_version_from   => 'lib/PostScript/LabelSheet.pm',
    build_requires => {
        'Test::More' => 0,
        'Class::Accessor' => 0,
        'parent' => 0,
        'Template' => 0,
    },
    add_to_cleanup      => [ 'PostScript-LabelSheet-*' ],
    create_makefile_pl => 'traditional',
    script => [ 'bin/pslabelsheet' ],
);

$builder->create_build_script();
