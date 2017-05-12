use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 48;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('PlugAuth');
$cluster->extract_data_section(qr{^var/data});
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

sub _allowed {
    my $path = shift;
    $t->get_ok("$url/authz/$path")
        ->status_is(200)
        ->content_is("ok", "authorization succeeded for $url");
}

sub _denied {
    my $path = shift;

    my($not_used, $user, $action, $resource) = split /\//, $path;

    $t->get_ok("$url/authz/$path")
        ->status_is(403)
        ->content_like(qr/^unauthorized : $user cannot $action \/$resource$/, "authorization denied for $url");
}

#
# Test various privileges as given in the sample authorization files.
#
_allowed('user/charliebrown/kick/football');
_allowed('user/CharlieBrown/kick/football');
_allowed('user/linus/kick/football');
_allowed('user/charliebrown/miss/football');
 _denied('user/linus/miss/football');
 _denied('user/Linus/miss/football');
 _denied('user/elmer/kick/football');
_allowed('user/thor/kick/football');
_allowed('user/thor/glob/globtest');

#
# Get a list of resources matching a regex for a particular
# user and action.
#
$t->get_ok("$url/authz/resources/thor/kick/.*ball")
  ->status_is(200)
  ->json_is('', ["/baseball","/football","/soccerball"]);

$t->get_ok("$url/authz/resources/tHOr/kick/.*ball")
  ->status_is(200)
  ->json_is('', ["/baseball","/football","/soccerball"]);

$t->get_ok("$url/actions")
  ->status_is(200)
  ->json_is('', [sort qw/create search miss view kick GET hit glob/]);

$t->get_ok("$url/groups/thor")->status_is(200)->json_is('', [qw/public superuser thor/]);

$t->get_ok("$url/groups/tHOr")->status_is(200)->json_is('', [qw/public superuser thor/]);

$t->get_ok("$url/groups/linus")->status_is(200)->json_is('', [qw/linus peanuts public/]);

$t->get_ok("$url/groups/nobody")->status_is(404);

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

