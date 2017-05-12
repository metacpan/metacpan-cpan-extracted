use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Rose::Planter',
    license             => 'perl',
    dist_author         => q{Brian Duggan <brian.duggan@nasa.gov>},
    dist_version_from   => 'lib/Rose/Planter.pm',
    build_requires => {
        'Test::More' => 0,
        'Path::Tiny' => 0,
        'Rose'       => 0,
        'JSON'       => 0, # require both this and
        'JSON::XS'   => 0, # this since rdbo::helper needs JSON.pm
        'Rose::DB::Object' => '0.789',
        'Module::Build::Database' => 0,
        'DBIx::Connector' => 0,
        'DateTime::Format::Pg' => 0,
        'DBD::SQLite' => 0,
        'Log::Log4perl' => 0,
        'Module::Find' => 0,
        'YAML::Syck' => 0, # optional Rose dependency
    },
    add_to_cleanup      => [ 'Rose-Planter-*' ],
);

$builder->create_build_script();
