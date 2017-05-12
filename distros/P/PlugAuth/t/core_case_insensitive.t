use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 95;
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

$t->get_ok(url('Primus:spark',"/auth"))
  ->status_is(200);

  $t->get_ok(url('primus:spark',"/auth"))
  ->status_is(200);
  
$t->get_ok(url('oPtimus:matrix',"/auth"))
  ->status_is(200);

$t->get_ok(url('Primus:bogus',"/auth"))
  ->status_is(403);

$t->get_ok(url('oPtimus:bogus',"/auth"))
  ->status_is(403);

$t->get_ok("$url/group")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( group1 group2 )], 'group = group1, group2';

$t->get_ok("$url/user")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus primus )], 'user = optimus, primus';

$t->get_ok("$url/groups/opTimus")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( group1 group2 optimus )], 'group optimus = group1, group2, optimus';

$t->get_ok("$url/users/grouP1")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus )], 'users group1 = optimus';

$t->get_ok("$url/users/groUp2")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus primus )], 'users group2 = optimus, primus';

$t->get_ok("$url/authz/user/optiMus/open/matrix")
  ->status_is(403);
$t->post_ok(url('PRimus:spark',"/grant/optImus/open/matrix"))
  ->status_is(200);
$t->get_ok("$url/authz/user/optiMus/open/matrix")
  ->status_is(200);
$t->delete_ok(url('prIMus:spark',"/grant/optIMus/open/matrix"))
  ->status_is(200);

$t->get_ok("$url/authz/resources/PRimUS/accounts/.*")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( / /user )], 'authz/resources/primus/accounts/.* = /, /user';

$t->get_ok(url('gRiMlOcK:foo',"/auth"))
  ->status_is(403);

$t->post_ok(url('prImUs:spark',"/user"), json { user => 'GrImLoCk', password => 'foo' })
  ->status_is(200);

$t->get_ok("$url/user")
  ->status_is(200);

ok scalar(grep { $_ eq 'grimlock' } @{ $t->tx->res->json }), 'created grimlock';

$t->get_ok(url('gRiMlOcK:foo',"/auth"))
  ->status_is(200);

$t->delete_ok(url('prIMUs:spark',"/user/grimLOCK"))
  ->status_is(200);
  
$t->get_ok("$url/user")
  ->status_is(200);

ok !scalar(grep { $_ eq 'grimlock' } @{ $t->tx->res->json }), 'deleted grimlock';

$t->get_ok(url('gRiMlOcK:foo',"/auth"))
  ->status_is(403);

$t->get_ok("$url/users/autobot")
  ->status_is(404);
  
$t->post_ok(url('pRIMUs:spark',"/group"), json { group => 'autoBot', users => 'priMUS,optiMUS' })
  ->status_is(200);

$t->get_ok("$url/users/autObot")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus primus )], 'users autobot = optimus, primus';

$t->post_ok(url('primus:spark',"/group/AutoboT"), json { users => 'OPtiMUS' })
  ->status_is(200);

$t->get_ok("$url/users/auTObot")
  ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus )], 'users autobot = optimus';
  
$t->delete_ok(url('primus:spark',"/group/autoboT"))
  ->status_is(200);

$t->get_ok("$url/users/AUTObot")
  ->status_is(404);

$t->post_ok(url('primus:spark',"/user/opTIMus"), json { password => 'matrix2' })
  ->status_is(200);

$t->get_ok(url('OPTimuS:matrix2',"/auth"))
  ->status_is(200);

$t->get_ok(url('OPTimuS:matrix',"/auth"))
  ->status_is(403);

$t->post_ok(url('primus:spark',"/group"), json { group => 'Xornop', users => '' })
  ->status_is(200);

$t->get_ok("$url/users/xOrnop")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( )], 'xor = ""';

$t->post_ok(url('primus:spark',"/group/xoRnop"), json { users => 'pRiMuS' })
  ->status_is(200);

$t->get_ok("$url/users/xOrnop")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( primus )], 'xor = primus';

$t->post_ok(url('primus:spark',"/group/xorNop/optIMUS"))
  ->status_is(200);

$t->get_ok("$url/users/xOrnop")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( primus optimus )], 'xor = primus, optimus';

$t->delete_ok(url('primus:spark',"/group/xornOp/PrImus"))
  ->status_is(200);

$t->get_ok("$url/users/xornoP")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus )], 'xor = optimus';

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
pRiMuS:tHeyAAmxTDjms
oPtImUs:nQN3EH9NZlhds


@@ var/data/group
gRoUp1: optImus
gRoUp2: *


@@ var/data/host


@@ var/data/resource
/ (accounts): PRimus
/user (change_password): primus

