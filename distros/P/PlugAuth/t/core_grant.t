use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 44;
use JSON::MaybeXS qw( encode_json );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

sub json($) {
    ( { 'Content-Type' => 'application/json' }, encode_json(shift) );
}

sub url {
  my $url = $url->clone;
  my $path = pop;
  my $userinfo = shift;
  $url->path($path);
  $url->userinfo($userinfo) if defined $userinfo;
  $url;
};

# grant an action on a resource to a group
$t->get_ok(url("/authz/user/optimus/open/matrix"))
    ->status_is(403)
    ->content_is("unauthorized : optimus cannot open /matrix", "denied optimus");

$t->get_ok(url("/authz/user/rodimus/open/matrix"))
    ->status_is(403)
    ->content_is("unauthorized : rodimus cannot open /matrix", "denied rodimus");

my $args = {};
$cluster->apps->[0]->once(grant => sub { my $e = shift; $args = shift });

$t->post_ok(url('primus:snoopy',"/grant/group1/open/matrix"))
    ->status_is(200)
    ->content_is("ok");

is $args->{admin},    'primus', 'admin = primus';
is $args->{group},    'group1', 'group = group1';
is $args->{action},   'open',   'action = open';
is $args->{resource}, 'matrix', 'resource = matrix';

$t->get_ok(url("/authz/user/optimus/open/matrix"))
    ->status_is(200)
    ->content_is("ok", "ok optimus");

$t->get_ok(url("/authz/user/rodimus/open/matrix"))
    ->status_is(200)
    ->content_is("ok", "ok rodimus");

# grant an action on a resource to a user
$t->get_ok(url("/authz/user/starscream/thwart/megatron"))
    ->status_is(403)
    ->content_is("unauthorized : starscream cannot thwart /megatron", "denied megatron");

$t->post_ok(url('primus:snoopy',"/grant/starscream/thwart/megatron"))
    ->status_is(200)
    ->content_is('ok');

$t->get_ok(url("/authz/user/starscream/thwart/megatron"))
    ->status_is(200)
    ->content_is("ok", "ok megatron");

# grant an action on a resource to a non existent group/user
$t->get_ok(url("/authz/user/unicron/fear/matrix"))
    ->status_is(403)
    ->content_is("unauthorized : unicron cannot fear /matrix", "denied unicron");

$t->post_ok(url('primus:snoopy', "/grant/unicron/fear/matrix"))
    ->status_is(404)
    ->content_is("not ok", "stuff");

$t->get_ok(url("/authz/user/unicron/fear/matrix"))
    ->status_is(403)
    ->content_is("unauthorized : unicron cannot fear /matrix", "denied unicron");

# attempt to grant with bogus credentials
$t->post_ok(url('primus:badpass',"/grant/group1/transform/cog"))
    ->status_is(401)
    ->content_is("authentication failure", "denied primus");

# grant to a group with an @ in the name (since groups can be users)
$t->post_ok(url('primus:snoopy', "/grant/prime\@autobot.mil/leadership/matrix"))
    ->status_is(200)
    ->content_is('ok', 'ok prime@autobot.mil');

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
optimus:snCedLzbuy6yg
rodimus:snCedLzbuy6yg
huffer:snCedLzbuy6yg
grimlock:snCedLzbuy6yg
nightbeat:snCedLzbuy6yg
starscream:snCedLzbuy6yg
soundwave:snCedLzbuy6yg
primus:snCedLzbuy6yg
prime@autobot.mil:snCedLzbuy6yg


@@ var/data/group
public  : *
group1  : optimus,rodimus


@@ var/data/host


@@ var/data/resource
/grant (accounts) : primus


