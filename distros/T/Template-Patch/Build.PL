use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Patch',
    license             => 'perl',
    dist_author         => 'Gaal Yahas <gaal@forum2.org>',
    dist_version_from   => 'lib/Template/Patch.pm',
    build_requires => {
        'Class::Accessor::Ref' => 0,
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'Template' => 0,
        'Template::Extract' => 0,
    },
    script_files        => [ qw< bin/metapatch/ > ],
    sign                => 1,
    add_to_cleanup      => [ 'Template-Patch-*' ],
);

$builder->create_build_script();
