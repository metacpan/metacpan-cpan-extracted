use strict;
use warnings;
use Test::Clustericious::Cluster 0.25;
use Test::More;

plan skip_all => 'Test requires DBD::SQLite' unless eval q{ require DBD::SQLite; 1 };
plan tests => 9;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('PlugAuth');
my $app = $cluster->apps->[0];

isa_ok $app, 'PlugAuth';
isa_ok $app->auth, 'PlugAuth::Plugin::DBIAuth';

$app->auth->dbh->do('INSERT INTO users (username, password) VALUES (?,?)', undef, 'optimus','ZL3D6w7QAFAK.'); # optimus:matrix

is $app->auth->check_credentials('optimus',   'matrix'), 1, "optimus matrix is good";
is $app->auth->check_credentials('optimus',   'badpas'), 0, "optimus badpas is bad";
is $app->auth->check_credentials('galvatron', 'matrix'), 0, "galvatron matrix is bad";

$app->auth->dbh->do('INSERT INTO users (username, password) VALUES (?,?)', undef, 'rodimus', '$apr1$WHAldQQD$eQdIoS1n9pVIkYTxPoGl.0'); # rodimus:cybetron

is $app->auth->check_credentials('rodimus',   'cybertron'), 1, "rodimus cybertron is good";
is $app->auth->check_credentials('rodimus',   'badpas'),    0, "rodimus badpas is bad";
is $app->auth->check_credentials('galvatron', 'matrix'),    0, "galvatron matrix is bad";

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
        check_credentials: SELECT password FROM users WHERE username = ?
        init: CREATE TABLE users ( username VARCHAR, password VARCHAR )


