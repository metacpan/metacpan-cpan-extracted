use strict;
use warnings;
use Module::Build 0.31;

my $builder = Module::Build->new(
    module_name         => 'Module::Build::Database',
    license             => 'perl',
    dist_author         => q{Brian Duggan <brian.duggan@nasa.gov>},
    dist_version_from   => 'lib/Module/Build/Database.pm',
    build_requires => {
        'Test::More' => 0,
        'File::Copy::Recursive' => 0,
        'IO::Socket::INET' => 0,
    },
    requires => {
        perl              => '5.10.0',
        'Digest::MD5' => 0,
        'File::Copy::Recursive' => 0,
        'Sub::Exporter' => 0,
        'blib'          => 0,
        'List::MoreUtils' => 0,
        'File::Which'     => 0,
        'File::ShareDir'  => 0,
        'Path::Class'     => 0,
    },
    add_to_cleanup      => [ 'Module-Build-Database-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
