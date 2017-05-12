use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 86;
use JSON::MaybeXS qw( encode_json );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

my $event_triggered = 0;
$cluster->apps->[0]->on(user_list_changed =>  sub { $event_triggered = 1 });

sub json($) {
    ( { 'Content-Type' => 'application/json' }, encode_json(shift) );
}

sub url ($$@) {
  my($url, $path,@rest) = @_;
  $url = $url->clone;
  $url->path($path);
  wantarray ? ($url, @rest) : $url;
}

# creating a user without credentials should return a 401
$t->post_ok(url $url, "/user", json { user => 'donald', password => 'duck' } )
    ->status_is(401)
    ->content_is("auth required", "attempt to create a user without credentials");

is $event_triggered, 0, 'event NOT triggered';
$event_triggered = 0;

# creating a user with bogus credentials should return 403
$url->userinfo('bogus:passs');
$t->post_ok(url $url, "/user", json { user => 'donald', password => 'duck' } )
    ->status_is(401)
    ->content_is("authentication failure", "attempt to create with bogus credentials");

is $event_triggered, 0, 'event NOT triggered';
$event_triggered = 0;

# creating a user without credentials or with bogus credentials (above) should not change the
# password file
$url->userinfo(undef);
$t->get_ok(url $url, "/user");
is grep(/^donald$/, @{ $t->tx->res->json }), 0, "donald was not created";

is $event_triggered, 0, 'event NOT triggered';
$event_triggered = 0;

$url->userinfo('donald:duck');
$t->get_ok(url $url, "/auth")
    ->status_is(403)
    ->content_is("not ok", 'auth does not work with user created without authenticating');

$url->userinfo('newuser:newpassword');
$t->get_ok(url $url, "/auth")
    ->status_is(403)
    ->content_is("not ok", 'auth does not work before user created');

$url->userinfo('elmer:fudd');
$t->post_ok(url $url, "/user", json { user => 'newuser' })
    ->status_is(403)
    ->content_is('not ok', 'cannot create user without a password');

$url->userinfo('elmer:fudd');
$t->post_ok(url $url, "/user", json { password => 'newpassword' })
    ->status_is(403)
    ->content_is('not ok', 'cannot create user without a user');

is $event_triggered, 0, 'event NOT triggered';
$event_triggered = 0;

do {
  my $args = {};
  $cluster->apps->[0]->once(create_user => sub { my $e = shift; $args = shift });

  $url->userinfo('elmer:fudd');
  $t->post_ok(url $url, "/user", json { user => 'newuser', password => 'newpassword' })
    ->status_is(200)
    ->content_is("ok", "created newuser");
    
  is $args->{admin}, 'elmer',   'admin = elmer';
  is $args->{user},  'newuser', 'user  = newuser';
};

is $event_triggered, 1, 'event triggered!';
$event_triggered = 0;

$url->userinfo('newuser:newpassword');
$t->get_ok(url $url, "/auth")
    ->status_is(200)
    ->content_is("ok", 'auth works after user created');

$url->userinfo(undef);
$t->get_ok(url $url, "/user");
is grep(/^newuser$/, @{ $t->tx->res->json }), 1, "newuser was created";

# user should get added to public group which is set to *
$t->get_ok(url $url, "/users/public");
is grep(/^newuser$/, @{ $t->tx->res->json }), 1, "newuser belongs to public";

$t->delete_ok(url $url, "/user/thor")
    ->status_is(401)
    ->content_is("auth required", "cannot delete user without credentials");

is $event_triggered, 0, 'event NOT triggered';
$event_triggered = 0;

$url->userinfo('baduser:badpassword');
$t->delete_ok(url $url, "/user/thor")
    ->status_is(401)
    ->content_is("authentication failure", "cannot delete user with bad credentials");

is $event_triggered, 0, 'event NOT triggered';
$event_triggered = 0;

$url->userinfo(undef);
$t->get_ok(url $url, "/user");
is grep(/^thor$/, @{ $t->tx->res->json }), 1, "thor is not deleted in failed delete";

$t->get_ok(url $url, "/user");
is grep(/^charliebrown$/, @{ $t->tx->res->json }), 1, "charlie brown exists before he is deleted";

$url->userinfo('charliebrown:snoopy');
$t->get_ok(url $url, "/auth")
    ->status_is(200)
    ->content_is("ok", "auth works before user is deleted");

$url->userinfo(undef);
$t->get_ok(url $url, "/user");
is grep(/^charliebrown$/, @{ $t->tx->res->json }), 1, "charlie brown not deleted in failed delete";

do {
  my $args = {};
  $cluster->apps->[0]->once(delete_user => sub { my $e = shift; $args = shift });

  $url->userinfo('elmer:fudd');
  $t->delete_ok(url $url, "/user/charliebrown")
    ->status_is(200)
    ->content_is("ok", "delete user");
  
  is $args->{admin}, 'elmer',        'admin = elmer';
  is $args->{user},  'charliebrown', 'user = charliebrown';
};

is $event_triggered, 1, 'event triggered!';
$event_triggered = 0;

$url->userinfo('charliebrown:snoopy');
$t->get_ok(url $url, "/auth")
    ->status_is(403)
    ->content_is("not ok", "auth fails after user is deleted");

$url->userinfo(undef);
$t->get_ok(url $url, "/user");
is grep(/^charliebrown$/, @{ $t->tx->res->json }), 0, "charlie brown does not exists after he is deleted";

# deleted users should be removed from the public group which  is set to *
$url->userinfo(undef);
$t->get_ok(url $url, "/users/public");
is grep(/^charliebrown$/, @{ $t->tx->res->json }), 0, "charlie brown is not in the public group";

$url->userinfo('nEwuSer1:newpassword');
$t->get_ok(url $url, "/auth")
    ->status_is(403)
    ->content_is("not ok", 'mixed case user password auth before create');

$url->userinfo('elmer:fudd');
$t->post_ok(url $url, "/user", json { user => 'NewUser1', password => 'newpassword' })
    ->status_is(200)
    ->content_is("ok", "mixed case user");

$url->userinfo('nEwuSer1:newpassword');
$t->get_ok(url $url, "/auth")
    ->status_is(200)
    ->content_is("ok", 'mixed case user password auth after create');

$url->userinfo('nEwuSer1:badpassword');
$t->get_ok(url $url, "/auth")
    ->status_is(403)
    ->content_is("not ok", 'mixed case user password auth after create bad password');

$url->userinfo('elmer:fudd');
$t->delete_ok(url $url, "/user/nEwuSeR1")
    ->status_is(200)
    ->content_is("ok", "mixed case user delete");

$url->userinfo('nEwuSer1:newpassword');
$t->get_ok(url $url, "/auth")
    ->status_is(403)
    ->content_is("not ok", 'mixed case user password auth after delete');

__DATA__
@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>

user_file:
  - <%= home %>/var/data/user
  - <%= home %>/var/data/more_users
group_file: <%= home %>/var/data/group
host_file: <%= home %>/var/data/host
resource_file: <%= home %>/var/data/resource

plug_auth:
  url: <%= cluster->url %>

@@ var/data/resource
/user (accounts) : elmer


@@ var/data/user
charliebrown:snCedLzbuy6yg
linus:AR2NVnqrzOh2M
elmer:fucVibC2NzOtg
thor:fucVibC2NzOtg
this.user.has.a.dot@dot.com:fucVibC2NzOtg


@@ var/data/more_users
#
# A secondary users file.
#
# The format of this is
# <username>:<crypted password>
# Lines beginning with a # and blank
# lines are ignored.

elmer:glJPWDD1HWjcc


@@ var/data/host
# empty

@@ var/data/group
#
# Group file.
#
# The format of this is --
# <groupname> : user1,user2,...
#
public  : *
peanuts : charliebrown,linus
superuser : thor

