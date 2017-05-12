use Module::Build::Database;

my $builder = Module::Build::Database->new(
  dist_abstract => 'dist for PgappA',
  database_type => 'PostgreSQL',
  dist_author => 'Author Man',
  database_options => {
    name => "castle",
    schema => "red",
  },
  module_name => 'PgappA',
  dist_version => '0.01',
  license => 'perl',
  configure_requires => {
    'Module::Build'           => 0.40, 
    'Module::Build::Database' => 0.48,
  },
);

$builder->create_build_script;

1;
