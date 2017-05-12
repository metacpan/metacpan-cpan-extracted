use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 16;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

$t->get_ok("$url/user")
    ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( bar charliebrown deckard elmer linus this.user.has.a.dot@dot.com thor )], 'full user list';
    
$t->get_ok("$url/users/peanuts")
    ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( charliebrown linus )], 'list of users belonging to peanuts';
    
$t->get_ok("$url/users/public")
    ->status_is(200);

is_deeply [sort @{ $t->tx->res->json }], [sort qw( bar charliebrown deckard elmer linus this.user.has.a.dot@dot.com thor )], 'list of users belonging to public';
    
$t->get_ok("$url/users/superuser")
    ->status_is(200)
    ->json_is('', [
        'thor',
    ], 'list of users belonging to superuser');

$t->get_ok("$url/users/bogus")
    ->status_is(404)
    ->content_is('not ok');

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

