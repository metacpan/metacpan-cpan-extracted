use strict;
use warnings;
use Test::More tests => 6;
use Module::Build::Database;
use Module::Build::Database::SQLite;
use Module::Build::Database::PostgreSQL;

#use YAML ();
#diag YAML::Dump(
#  [Module::Build::Database->hash_properties],
#  [Module::Build::Database::SQLite->hash_properties],
#  [Module::Build::Database::PostgreSQL->hash_properties],
#);

foreach my $class (qw( Module::Build::Database Module::Build::Database::SQLite Module::Build::Database::PostgreSQL ))
{
  is int(grep { $_ eq 'install_path' } $class->hash_properties), 1, "$class has install_path property";
}

is int(grep { $_ eq 'database_options' } Module::Build::Database::SQLite->hash_properties), 1, "Module::Build::Database::SQLite has database_options property";
is int(grep { $_ eq 'database_options' } Module::Build::Database::PostgreSQL->hash_properties), 1, "Module::Build::Database::PostgreSQL has database_options property";
is int(grep { $_ eq 'database_extensions' } Module::Build::Database::PostgreSQL->hash_properties), 1, "Module::Build::Database::PostgreSQL has database_extensions property";
