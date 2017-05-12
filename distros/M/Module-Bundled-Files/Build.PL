use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Bundled::Files',
    license             => 'perl',
    dist_author         => 'Paul Campbell <kemitix@gmail.com>',
    dist_version_from   => 'lib/Module/Bundled/Files.pm',
    requires => {
        'Module::Build'
                     => 0.26, # add_build_element() appears in 0.2607
        'Test::More' => 0,
        'File::Spec' => 0,
        'Class::ISA'  => 0,
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Module-Bundled-Files-*' ],
);

$builder->create_build_script();
