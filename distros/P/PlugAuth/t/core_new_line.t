use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 21;
use JSON::MaybeXS qw( encode_json );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

sub json($) {
    ( { 'Content-Type' => 'application/json' }, encode_json(shift) );
}

sub url ($$@) {
  my($url, $path,@rest) = @_;
  $url = $url->clone;
  $url->path($path);
  wantarray ? ($url, @rest) : $url;
}

# creating a user with bogus credentials should return 403

$url->userinfo('primus:matrix');
$t->post_ok(url $url, '/user', json { user => 'donald', password => 'duck' } )
  ->status_is(200);

$t->get_ok(url $url, '/auth')
  ->status_is(200);

$url->userinfo('primus:bogus');
$t->get_ok(url $url, '/auth')
  ->status_is(403);

$url->userinfo('donald:duck');
$t->get_ok(url $url, '/auth')
  ->status_is(200);
  
$url->userinfo('optimus:matrix');
$t->get_ok(url $url, '/auth')
  ->status_is(200);

$url->userinfo('unicron:chaos');
$t->get_ok(url $url, '/auth')
  ->status_is(200);

$url->userinfo(undef);
$t->get_ok(url $url, '/groups/primus')
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( primus public ) ];

$url->userinfo('primus:matrix');
$t->post_ok(url $url, '/group', json { group => 'god', users => 'primus,unicron' })
  ->status_is(200);
  
$url->userinfo(undef);
$t->get_ok(url $url, '/groups/primus')
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( primus public god ) ];

__DATA__
@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
user_file: <%= home %>/var/data/user
group_file: <%= home %>/var/data/group
host_file: <%= home %>/var/data/host
resource_file: <%= home %>/var/data/resource
plug_auth:
  url: <%= cluster->url %>


@@ var/data/user
unicron:$apr1$FUS5Cvqu$Iz4bGkbVbdKLNOD1j66CQ0
primus:$apr1$ZotZ.g2P$1LRpYkEeat0wMFiwITX4t.
optimus:$apr1$mYZYu.n/$hJ6QfTDRsBzRNc35qcNnG0

@@ var/data/group
public: *


@@ var/data/host
# empty


@@ var/data/resource
/ (accounts) : primus
/user (change_password) : primus

