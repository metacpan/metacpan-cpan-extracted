use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 58;

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

# First check that the groups are right at start.
$t->get_ok("$url/users/full1")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( foo bar baz primus )], "at start full1 = foo bar baz";
$t->get_ok("$url/users/full2")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( foo bar baz primus )], "at start full2 = foo bar baz";
$t->get_ok("$url/users/part1")
  ->status_is(200);
is_deeply [@{ $t->tx->res->json }], ['foo'], "at start part1 = foo";
$t->get_ok("$url/users/part2")
  ->status_is(200);
is_deeply [@{ $t->tx->res->json }], ['baz'], "at start part2 = baz";

# next add bar to part1
$t->post_ok(url('primus:primus',"/group/part1/bar"))
  ->status_is(200)
  ->content_is('ok');
$t->get_ok("$url/users/part1")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( foo bar) ], "at start part1 = foo bar";

# next add to a non-existent group
$t->post_ok(url('primus:primus',"/group/bogus/foo"))
  ->status_is(404)
  ->content_is('not ok');
$t->get_ok("$url/users/bogus")
  ->status_is(404)
  ->content_is('not ok');

# add bar and baz to part2
$t->post_ok(url('primus:primus',"/group/part2/bar"))
  ->status_is(200)
  ->content_is('ok');
$t->post_ok(url('primus:primus',"/group/part2/foo"))
  ->status_is(200)
  ->content_is('ok');
$t->get_ok("$url/users/part2")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( foo bar baz) ], "at start part2 = foo bar baz";

# add foo to full1 and full2
$t->post_ok(url('primus:primus',"/group/full1/bar"))
  ->status_is(200)
  ->content_is('ok');
$t->get_ok("$url/users/full1")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( foo bar baz primus) ], "at start full1 = foo bar baz primus";

$t->post_ok(url('primus:primus',"/group/full2/bar"))
  ->status_is(200)
  ->content_is('ok');
$t->get_ok("$url/users/full2")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( foo bar baz primus) ], "at start full2 = foo bar baz primus";

# remove foo from full3 and full4
$t->delete_ok(url('primus:primus',"/group/full3/foo"))
  ->status_is(200)
  ->content_is('ok');
$t->get_ok("$url/users/full3")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( bar baz primus) ], "at start full3 = foo bar baz primus";

$t->delete_ok(url('primus:primus',"/group/full4/foo"))
  ->status_is(200)
  ->content_is('ok');
$t->get_ok("$url/users/full4")
  ->status_is(200);
is_deeply [sort @{ $t->tx->res->json }], [sort qw( bar baz primus) ], "at start full4 = foo bar baz primus";

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
foo:kXdmy/G8gIr6E
bar:We/RNrO28Rd/E
baz:MsKrxsuIrbHLU
primus:73Dh1aWX7Sm2g


@@ var/data/group
full1: foo,bar,baz,primus
full2: *
part1: foo
part2: baz
full3: foo,bar,baz,primus
full4: *

@@ var/data/host
# empty


@@ var/data/resource
/group (accounts): primus

