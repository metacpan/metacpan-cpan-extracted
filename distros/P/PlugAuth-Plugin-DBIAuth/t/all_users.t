use strict;
use warnings;
use Test::Clustericious::Cluster 0.25;
use Test::More;

plan skip_all => 'Test requires DBD::SQLite' unless eval q{ require DBD::SQLite; 1 };
plan tests => 5;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('PlugAuth');

my $app = $cluster->apps->[0];
isa_ok $app, 'PlugAuth';
isa_ok $app->auth, 'PlugAuth::Plugin::DBIAuth';

is_deeply [ sort $app->auth->all_users ], [], "all_users = ()";

$app->auth->dbh->do('INSERT INTO users (username) VALUES (?)', undef, $_) for (qw( foo bar baz ));

is_deeply [ sort $app->auth->all_users ], [sort qw( foo bar baz )], "all_users = foo bar baz";

__DATA__

@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
plugins:
  - PlugAuth::Plugin::DBIAuth:
      db:
        dsn: dbi:SQLite:dbname=<%= home %>/auth.sqlite
        user: ''
        pass: ''
      sql:
        all_users: SELECT username FROM users
        init: CREATE TABLE users ( username VARCHAR, password VARCHAR )

