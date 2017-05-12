use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 53;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok(qw( PlugAuth ));
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

$t->get_ok("$url/")
  ->status_is(200)
  ->content_like(qr/welcome/, 'welcome message!')
  ->content_type_like(qr{^text/plain(;.*)?$});

# missing user + pw
$t->get_ok("$url/auth")
  ->status_is(401)
  ->content_like(qr[authenticate], 'got authenticate header');

sub url ($$)
{
  my($url,$path) = @_;
  $url = $url->clone;
  $url->path($path);
  $url;
}

# good user
$url->userinfo('charliebrown:snoopy');
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", 'auth succeeded');

# good user with funky name
$url->userinfo("this.user.has.a.dot\@dot.com:fudd");
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", 'auth succeeded');

# good user in two places
$url->userinfo('elmer:fudd');
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", 'auth succeeded');

$url->userinfo('elmer:glue');
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", 'auth succeeded');

# unknown user
$url->userinfo('charliebrown:snoopy');
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", 'auth succeeded');

# bad pw
$url->userinfo('charliebrown:badpass');
$t->get_ok(url $url, '/auth')
  ->status_is(403)
  ->content_is("not ok", 'auth failed');

# missing pw
$url->userinfo('charliebrown');
$t->get_ok(url $url, '/auth')
  ->status_is(403)
  ->content_is("not ok", 'auth failed');

# check for trusted host
$url->userinfo(undef);
$t->get_ok(url $url, '/host/127.9.9.9/trusted')
  ->status_is(200)
  ->content_is("ok", "trusted host");

$t->get_ok(url $url, '/host/123.123.123.123/trusted')
  ->status_is(403)
  ->content_is("not ok", "untrusted host");

# good user with mixed case
$url->userinfo('CharlieBrown:snoopy');
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", 'case insensative username');

# bad pw
$url->userinfo('CharlieBrown:badpass');
$t->get_ok(url $url, '/auth')
  ->status_is(403)
  ->content_is("not ok", 'case insensative username auth failed');

# apache md5
$url->userinfo('deckard:androidsdream');
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", "apache md5 password is okay");

$url->userinfo('deckard:androidsdreamx');
$t->get_ok(url $url, '/auth')
  ->status_is(403)
  ->content_is("not ok", "bad apache md5 password is not okay");

# unix md5
$url->userinfo('bar:foo');
$t->get_ok(url $url, '/auth')
  ->status_is(200)
  ->content_is("ok", "unix md5 password is okay");

$url->userinfo('foo:foox');
$t->get_ok(url $url, '/auth')
  ->status_is(403)
  ->content_is("not ok", "bad unix md5 password is not okay");

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
#
# Resources file
#
# The format of this is :
# <resource> (<action>) : <group>, <group>, ...
#
# Note that every user is also in a group of their own
# name, so the <group< can also be the name of a user.
#

/ (kick) : superuser
/football (kick) : peanuts
/football (miss) : charliebrown
/baseball (hit) :
/soccerball (kick) : charliebrown
/esdt (view) : elmer
/ (view) : superuser
/ (search) : superuser
/ (create) : superuser
/methodpath (GET) : charliebrown
/globtest (glob) : public


@@ var/data/user
#
# users file.
#
# The format of this is
# <username>:<crypted password>
# Lines beginning with a # and blank
# lines are ignored.


charliebrown:snCedLzbuy6yg
linus:AR2NVnqrzOh2M
elmer:fucVibC2NzOtg
thor:fucVibC2NzOtg
this.user.has.a.dot@dot.com:fucVibC2NzOtg
deckard:$apr1$vyS3rvbH$Ye8UqFG2CKAbdrFYMPHVY1
bar:$apr1$xt$Mx3soOiejI3LQaZqJFlvL/


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
127.9.9.9: trusted
127.0.0.1: trusted


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


