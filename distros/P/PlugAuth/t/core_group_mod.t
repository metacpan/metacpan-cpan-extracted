use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 104;
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

# creating a group without credentials should return a 401
$t->post_ok(url $url, '/group', json { group => 'group1' } )
    ->status_is(401)
    ->content_is("auth required", "attempt to create group without credentials");

$t->get_ok(url $url, '/group');
is grep(/^group1$/, @{ $t->tx->res->json }), 0, "group1 was not created";

# creating a group with bogus credentials should return 403
$url->userinfo('bogus:pass');
$t->post_ok(url $url, '/group', json { group => 'group2' } )
    ->status_is(401)
    ->content_is("authentication failure", "attempt to create with bogus credentials");

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group2$/, @{ $t->tx->res->json }), 0, "group2 was not created";

# create an empty group
$url->userinfo('huffer:snoopy');
$t->post_ok(url $url, '/group', json { group => 'group3' } )
    ->status_is(200)
    ->content_is("ok", "create group3 (empty)");

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group3$/, @{ $t->tx->res->json }), 1, "group3 was created";

$t->get_ok(url $url, '/users/group3')
    ->json_is('', [], "group3 is empty");

do {
  my $args = {};
  $cluster->apps->[0]->once(create_group => sub { my $e = shift; $args = shift });

  # create an group with four users
  $url->userinfo('huffer:snoopy');
  $t->post_ok(url $url, '/group', json { group => 'group4', users => 'optimus,rodimus,huffer,grimlock' } )
    ->status_is(200)
    ->content_is("ok", "create group4 (optimus,rodimus,huffer,grimlock)");
    
  is $args->{admin}, 'huffer', 'admin = huffer';
  is $args->{group}, 'group4', 'group = group4';
  is $args->{users}, 'optimus,rodimus,huffer,grimlock', 'users = optimus,rodimus,huffer,grimlock';
};

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group4$/, @{ $t->tx->res->json }), 1, "group4 was created";

$t->get_ok(url $url, '/users/group4');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus rodimus huffer grimlock )], 'group4 is not empty';
    
# remove a group
$t->get_ok(url $url, '/group');
is grep(/^group5$/, @{ $t->tx->res->json }), 1, "group5 exists";

do {
  my $args = {};
  $cluster->apps->[0]->once(delete_group => sub { my $e = shift; $args = shift });

  $url->userinfo('huffer:snoopy');
  $t->delete_ok(url $url, '/group/group5')
    ->status_is(200)
    ->content_is("ok", "delete group5");

  is $args->{admin}, 'huffer', 'admin = huffer';
  is $args->{group}, 'group5', 'group = group5';
};

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group5$/, @{ $t->tx->res->json }), 0, "group5 deleted";

# remove a non existent group
$t->get_ok(url $url, '/group');
is grep(/^group6/, @{ $t->tx->res->json }), 0, "group6 does not exist";

$url->userinfo('huffer:snoopy');
$t->delete_ok(url $url, '/group/group6')
    ->status_is(404)
    ->content_is("not ok", "cannot delete non existent group");

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group6/, @{ $t->tx->res->json }), 0, "group6 (still) does not exist";

# create an already existing group
$t->get_ok(url $url, '/group');
is grep(/^group7/, @{ $t->tx->res->json }), 1, "group7 exists";

$url->userinfo('huffer:snoopy');
$t->post_ok(url $url, '/group', json { group => 'group7', users => 'foo,bar,baz' })
    ->status_is(403)
    ->content_is('not ok', 'cannot create already existing group7');

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group7/, @{ $t->tx->res->json }), 1, "group7 (still) exists";

$url->userinfo('huffer:snoopy');
$t->get_ok(url $url, '/users/group7')
    ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( grimlock rodimus )], 'group7 is [grimlock,rodimus]';

# creating a group with a real user but bad password
$url->userinfo('huffer:pass');
$t->post_ok(url $url, '/group', json { group => 'group8' } )
    ->status_is(401)
    ->content_is("authentication failure", "attempt to create with bogus credentials");

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group8$/, @{ $t->tx->res->json }), 0, "group8 was not created";

# change the user membership of an existing group
$t->get_ok(url $url, '/users/group9');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( nightbeat starscream soundwave )], "group9 is [ nightbeat,starscream,soundwave ]";

do {
  my $args = {};
  $cluster->apps->[0]->once(update_group => sub { my $e = shift; $args = shift });

  $url->userinfo('huffer:snoopy');
  $t->post_ok(url $url, '/group/group9', json { users => "optimus,rodimus,huffer,grimlock" })
    ->status_is(200)
    ->content_is("ok");
    
  is $args->{admin}, 'huffer', 'admin = huffer';
  is $args->{group}, 'group9', 'group = group9';
  is $args->{users}, "optimus,rodimus,huffer,grimlock", 'users = optimus,rodimus,huffer,grimlock';
};

$url->userinfo(undef);
$t->get_ok(url $url, '/users/group9');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( optimus rodimus huffer grimlock )], 'group9 is [ optimus,rodimus,huffer,grimlock ]';
    
# remove all users from a group
$t->get_ok(url $url, '/users/group10');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( nightbeat starscream soundwave )], "group10 is [ nightbeat,starscream,soundwave ]";

$url->userinfo('huffer:snoopy');
$t->post_ok(url $url, '/group/group10', json { users => '' })
    ->status_is(200)
    ->content_is("ok");

$url->userinfo(undef);
$t->get_ok(url $url, '/users/group10')
    ->json_is('', [], "group10 is empty");

# change user membership of an existing group with an invalid username
$t->get_ok(url $url, '/users/group11');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( nightbeat starscream soundwave )], "group11 is [ nightbeat,starscream,soundwave ]";

$url->userinfo('huffer:snoopy');
$t->post_ok(url $url, '/group/group11', json { users => "optimus,foo,bar,baz" })
    ->status_is(200)
    ->content_is("ok");

$url->userinfo(undef);
$t->get_ok(url $url, '/users/group11')
    ->json_is('', [sort qw( optimus )], "group11 is [ optimus ]");

# change user membership of a non existent group
$t->get_ok(url $url, '/group');
is grep(/^group12$/, @{ $t->tx->res->json }), 0, "no group 12";

$url->userinfo('huffer:snoopy');
$t->post_ok(url $url, '/group/group12', json { users => "optimus,rodimus,huffer,grimlock" })
    ->status_is(404)
    ->content_is("not ok");

$url->userinfo(undef);
$t->get_ok(url $url, '/group');
is grep(/^group12$/, @{ $t->tx->res->json }), 0, "(still) no group 12";

# change user membership of an existing group with bad credentials
$t->get_ok(url $url, '/users/group14');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( nightbeat starscream soundwave )], "group14 is [ nightbeat,starscream,soundwave ]";

$url->userinfo('huffer:bogus');
$t->post_ok(url $url, '/group/group14', json { users => "optimus,rodimus,huffer,grimlock" })
    ->status_is(401)
    ->content_is("authentication failure");

$url->userinfo(undef);
$t->get_ok(url $url, '/users/group14');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( nightbeat starscream soundwave )], "group14 is (still) [ nightbeat,starscream,soundwave ]";

# update group without providing user field
$t->get_ok(url $url, '/users/group15');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( nightbeat starscream soundwave )], "group15 is [ nightbeat,starscream,soundwave ]";

$url->userinfo('huffer:snoopy');
$t->post_ok(url $url, '/group/group15', json {})
    ->status_is(200)
    ->content_is("ok");

$url->userinfo(undef);
$t->get_ok(url $url, '/users/group15');

is_deeply [sort @{ $t->tx->res->json }], [sort qw( nightbeat starscream soundwave )], "group15 is (still) [ nightbeat,starscream,soundwave ]";

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


@@ var/data/group
public  : *
group5  : grimlock,optimus,rodimus
group7  : grimlock,rodimus
group9  : nightbeat,starscream,soundwave
group10 : nightbeat,starscream,soundwave
group11 : nightbeat,starscream,soundwave
group14 : nightbeat,starscream,soundwave
group15 : nightbeat,starscream,soundwave


@@ var/data/host


@@ var/data/resource
/group (accounts) : huffer


