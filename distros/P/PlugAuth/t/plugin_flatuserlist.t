use strict;
use warnings;
use autodie;
use Test::Clustericious::Cluster;
use Test::More tests => 19;
use File::HomeDir;
use File::Spec;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

sub url ($$@) {
  my($url, $path,@rest) = @_;
  $url = $url->clone;
  $url->path($path);
  wantarray ? ($url, @rest) : $url;
}

isa_ok $cluster->apps->[0]->auth, 'PlugAuth::Plugin::FlatUserList';
isa_ok $cluster->apps->[0]->app->auth->next_auth, 'PlugAuth::Plugin::FlatAuth';
is $cluster->apps->[0]->auth->next_auth->next_auth, undef, 'app->auth->next_auth->next_auth is undef';

$url->userinfo('foo:foo');
$t->get_ok(url $url, "/auth")
  ->status_is(200)
  ->content_is("ok", 'auth succeeded');

$url->userinfo('bar:bar');
$t->get_ok(url $url, "/auth")
  ->status_is(403)
  ->content_is("not ok", 'auth succeeded');
  
$url->userinfo(undef);
$t->get_ok(url $url, "/user")
    ->status_is(200)
    ->json_is('', [sort
        qw( foo bar ralph bob george )
    ], 'full sorted user list');

do {
  open(my $fh, '>>', File::Spec->catfile(File::HomeDir->my_home, qw( var data ), 'user_list'));
  print $fh "optimus";
  close $fh;
  # fake it that the mtime is older for test
  $cluster->apps->[0]->auth->{mtime} -= 5;
};

$t->get_ok(url $url, "/user")
    ->status_is(200)
    ->json_is('', [sort
        qw( foo bar ralph bob george optimus )
    ], 'full sorted user list');

do {
  open(my $fh, '>', File::Spec->catfile(File::HomeDir->my_home, qw( var data ), 'user_list'));
  print $fh "one";
  close $fh;
  # fake it that the mtime is older for test
  $cluster->apps->[0]->auth->{mtime} -= 5;
};

$t->get_ok(url $url, "/user")
    ->status_is(200)
    ->json_is('', [sort
        qw( foo bar one )
    ], 'full sorted user list');

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
plugins:
  - PlugAuth::Plugin::FlatUserList:
      user_list_file: <%= home %>/var/data/user_list
  - PlugAuth::Plugin::FlatAuth: {}

@@ var/data/user_list
ralph
bob
george
bar


@@ var/data/user
foo:U5anayGrSoBQM
bar:/Rec/o5XAjSxk


@@ var/data/group
# empty


@@ var/data/host
# empty


@@ var/data/resource
# empty

