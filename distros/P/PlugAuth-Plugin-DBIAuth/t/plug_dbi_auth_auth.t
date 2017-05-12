use strict;
use warnings;
use Test::More;
use File::HomeDir::Test;
use Test::PlugAuth::Plugin::Auth;

unless(eval qq{ require DBD::SQLite; 1 })
{
  plan skip_all => 'Test requires DBD::SQLite';
}

my $home = File::HomeDir->my_home;
my $dbfile = File::Spec->catfile($home, 'auth.sqlite');

run_tests 'PlugAuth::Plugin::DBIAuth', {}, {
      db => {
        dsn  => "dbi:SQLite:dbname=$dbfile",
        user => '',
        pass => '',
      },
      sql => {
        check_credentials => "SELECT password FROM users WHERE username = ?",
        create_user       => "INSERT INTO users (username, password) VALUES (?,?)",
        change_password   => "UPDATE users SET password = ? WHERE username = ?",
        all_users         => "SELECT username FROM users",
        delete_user       => "DELETE FROM users WHERE username = ?",
        init              => "CREATE TABLE users ( username VARCHAR, password VARCHAR )",
      },
    };
