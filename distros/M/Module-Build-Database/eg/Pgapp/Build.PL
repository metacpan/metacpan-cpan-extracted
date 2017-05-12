use lib '../../lib';
use Module::Build::Database;

my $builder = Module::Build::Database->new(
          database_type => "PostgreSQL",
          database_options => {
              name => "scooby",
              schema => "doo",
          },
          database_extensions => {
              postgis => { schema => "postgis" },
          },
          postgis_base => "/util/share/postgresql/contrib",
          module_name => "Pgapp",
          dist_version => "0.1010101",
          license => "perl",
);

$builder->create_build_script;

1;

