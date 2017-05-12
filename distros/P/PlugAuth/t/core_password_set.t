use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 23;
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

# attempt to change password of optimus without credentials (fails)
$t->post_ok("$url/user/optimus", json { password => 'foo' } )
  ->status_is(401);

# double check password of optimus has not changed
$t->get_ok(url('optimus:optimus',"/auth"))
  ->status_is(200);

# empty password returns error
$t->post_ok(url('primus:primus',"/user/optimus"))
  ->status_is(403);

# double check password of optimus has not changed
$t->get_ok(url('optimus:optimus',"/auth"))
  ->status_is(200);

# attempt to change password of optimus with primus (super user)
my $args = {};
$cluster->apps->[0]->once(change_password => sub {
  my $e = shift;
  $args = shift;
});

$t->post_ok(url('primus:primus',"/user/optimus"), json { password => 'matrix' } )
  ->status_is(200);

is $args->{admin}, 'primus',  'admin = primus';
is $args->{user},  'optimus', 'user = optimus';

# double check that old credentials for optimus no longer work
$t->get_ok(url('optimus:optimus',"/auth"))
  ->status_is(403);

# double check that new credentials for optimus DOES work
$t->get_ok(url('optimus:matrix',"/auth"))
  ->status_is(200);

# bogus user returns error
$t->post_ok(url('primus:primus',"/user/bogus"), json { password => 'bar' } )
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
/user (accounts) : primus
/user (change_password) : primus

