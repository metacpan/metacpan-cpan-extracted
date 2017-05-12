use strict;
use warnings;
use Test::Clustericious::Log;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 17;
use JSON::MaybeXS qw( encode_json );

create_directory_ok 'data';

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( PlugAuth ));

my $url = $cluster->url;
my $t   = $cluster->t;
my $app = $cluster->apps->[0];

eval {
  $app->authz->create_group('foo', '');
  $app->authz->create_group('bar', '');
  $app->authz->create_group('baz', '');
};
diag $@ if $@;

sub json($) {
    ( { 'Content-Type' => 'application/json' }, encode_json(shift) );
}

$t->post_ok("$url/user", json { user => 'user1', password => 'password', groups => 'foo,bar' })
  ->status_is(200);

$t->post_ok("$url/user", json { user => 'user2', password => 'password', groups => 'foo' })
  ->status_is(200);

$t->post_ok("$url/user", json { user => 'user3', password => 'password' })
  ->status_is(200);

$t->get_ok("$url/users/foo")
    ->status_is(200);

is_deeply [sort @{ (eval { $t->tx->res->json } // []) }], [qw( user1 user2 )], 'foo = [user1, user2]';
diag $@ if $@;

$t->get_ok("$url/users/bar")
    ->status_is(200);

is_deeply [sort @{ (eval { $t->tx->res->json } // []) }], [qw( user1 )], 'bar = [user1]';
diag $@ if $@;

$t->get_ok("$url/users/baz")
    ->status_is(200);

is_deeply [sort @{ (eval { $t->tx->res->json } // []) }], [], 'baz = []';

__DATA__

@@ etc/PlugAuth.conf
---
% use File::Touch;
url: <%= cluster->url %>

% foreach my $file (qw( user group resource )) {
% touch(join '/', home, 'data', $file);
<%= $file %>_file: <%= home %>/data/<%= $file %>
% }
