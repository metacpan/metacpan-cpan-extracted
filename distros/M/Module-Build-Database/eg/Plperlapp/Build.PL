use Module::Build::Database;

my $builder = Module::Build::Database->new(
  dist_abstract => 'Postgres database with plperl',
  database_type => 'PostgreSQL',
  database_options => {
    name => "scooby",
    schema => "doo",
  },
  database_extensions => {
    languages => [ 'plperl' ],
  },
  module_name => 'Plperlapp',
  dist_version => '0.01',
  license => 'perl',
  configure_requires => {
    'Module::Build'           => 0.40, 
    'Module::Build::Database' => 0.48,
  },
);

$builder->create_build_script;

1;
