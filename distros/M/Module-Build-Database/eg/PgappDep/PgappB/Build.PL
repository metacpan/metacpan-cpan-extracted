use Module::Build::Database;

my $builder = Module::Build::Database->new(
  dist_abstract => 'dist for PgappB',
  database_type => 'PostgreSQL',
  dist_author => 'Author Man',
  database_options => {
    name         => "castle",
    schema       => "blue",
    after_create => do {
      my $sql = q{
        create schema red;
        set search_path = red;
      } . do {
        require File::ShareDir;
        open my $fh, '<', File::ShareDir::dist_file('PgappA', 'dist/base.sql');
        local $/;
        <$fh>;
      } . q{ set search_path = blue; };
    },
  },
  module_name => 'PgappB',
  dist_version => '0.01',
  license => 'perl',
  configure_requires => {
    'Module::Build'           => 0.40, 
    'Module::Build::Database' => 0.48,
    'PgappA'                  => 0,
    'File::ShareDir'          => 0,
  },
);

$builder->create_build_script;

1;
