use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Parse::GEDA::Gschem',
    license             => 'perl',
    dist_author         => 'JP Fricker <JPFRICKER@CPAN.org>',
    dist_abstract       => 'gEDA/gaf gschem file parser',
    dist_version_from   => 'lib/Parse/GEDA/Gschem.pm',
    requires => {
        'perl'              => '5.10.0',
        'File::Copy'        => 0,
        'File::Basename'    => 0,
        'Data::Dumper'      => 0,
        'Parse::RecDescent' => '1.96.0',
        'Test::More'        => 0,
        'version'           => 0,
        'Exporter'          => 0,
    },
    add_to_cleanup      => [ 'Parse-GEDA-Gschem-*' ],
);

$builder->create_build_script();
