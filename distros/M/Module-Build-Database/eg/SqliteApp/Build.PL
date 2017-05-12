use lib '../../lib';
use Module::Build::Database;

my $builder = Module::Build::Database->new(
          database_type => "SQLite",
          database_options => { name => "sqlite_app.db" },
          module_name => "SqliteApp",
          dist_version => "0.111000",
          dist_abstract => "test",
          license => "perl",
);

$builder->create_build_script;

1;

