use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 25;
use JSON::MaybeXS qw( encode_json );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

sub url {
  my $url = $url->clone;
  my $path = pop;
  my $userinfo = shift;
  $url->path($path);
  $url->userinfo($userinfo) if defined $userinfo;
  $url;
};

sub json($) {
  ( { 'Content-Type' => 'application/json' }, encode_json(shift) );
}

# double check initial password for optimus
$t->get_ok(url('optimus:optimus',"/auth"))
  ->status_is(200);

# double check initial password for primus (super user)
$t->get_ok(url('primus:primus',"/auth"))
  ->status_is(200);

# one user can't change another's password
$t->post_ok(url('primus:primus',"/user/optimus"), json { password => 'foo' } )
  ->status_is(403);

# one user can't change another's password
$t->post_ok(url('optimus:optimus',"/user/primus"), json { password => 'foo' } )
  ->status_is(403);

# passwords have not changed
$t->get_ok(url('optimus:optimus',"/auth"))
  ->status_is(200);

$t->get_ok(url('primus:primus',"/auth"))
  ->status_is(200);

# each user can change his/her own password
$t->post_ok(url('primus:primus',"/user/primus"), json { password => 'iamagod' } )
  ->status_is(200);

$t->post_ok(url('optimus:optimus',"/user/optimus"), json { password => 'matrix' } )
  ->status_is(200);

# passwords have changed
$t->get_ok(url('optimus:matrix', "/auth"))
  ->status_is(200);

$t->get_ok(url('primus:iamagod',"/auth"))
  ->status_is(200);

$t->get_ok(url('optimus:optimus',"/auth"))
  ->status_is(403);

$t->get_ok(url('primus:primus',"/auth"))
  ->status_is(403);

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
optimus:UoVhdjiPzItYA
primus:yo2CPgvcp4mzo


@@ var/data/group
public  : *


@@ var/data/host


@@ var/data/resource
/user/#u (change_password) : #u

