use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Build::PDL',
    license             => 'perl',
    dist_author         => 'David Mertens <dcmertens.perl@gmail.com>',
    dist_version_from   => 'lib/Module/Build/PDL.pm',
    requires => {
        'Test::More'    => 0,
        'version'       => 0,
        'Module::Build' => 0,
        'PDL'           => 0,
    },
    add_to_cleanup      => [ 'Module-Build-PDL-*' ],
);

$builder->create_build_script();
