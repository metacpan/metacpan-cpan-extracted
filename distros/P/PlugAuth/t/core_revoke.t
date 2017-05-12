use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 479;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

my $auth_url = $url->clone;
$auth_url->userinfo("primus:foo");

sub url ($$@) {
  my($url, $path,@rest) = @_;
  $url = $url->clone;
  $url->path($path);
  wantarray ? ($url, @rest) : $url;
}

do {
  # / (accounts): god
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(403)
    for qw( optimus grimlock starscream megatron skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(200)
    for qw( primus unicron );

  # /altmode (transform): public
  $t->get_ok(url $url, "/authz/user/$_/transform/altmode")->status_is(200)
    for qw( optimus grimlock starscream megatron skylynks swoop primus unicron );

  # /red (color): autobot
  # /purple (color): decepticon
  $t->get_ok(url $url, "/authz/user/$_/color/red")->status_is(200)
    for qw( optimus grimlock skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/color/purple")->status_is(200)
    for qw( starscream megatron );
    
  # /battle (retreat): megatron
  $t->get_ok(url $url, '/authz/user/megatron/retreat/battle')->status_is(200);
  $t->get_ok(url $url, "/authz/user/$_/retreat/battle")->status_is(403)
    for qw( optimus grimlock starscream skylynks swoop primus unicron );

  # /matrix (open): optimus
  $t->get_ok(url $url, '/authz/user/optimus/open/matrix')->status_is(200);
  $t->get_ok(url $url, "/authz/user/$_/open/matrix")->status_is(403)
    for qw( megatron grimlock starscream skylynks swoop primus unicron );
};

$t->delete_ok(url $url, '/grant/megatron/open/matrix')->status_is(401);
$t->delete_ok(url $url, '/grant/optimus/open/matrix')->status_is(401);
$t->delete_ok(url $auth_url, '/grant/megatron/open/matrix')
  ->status_is(404)->content_is('not ok');


do {
  my $args = {};
  $cluster->apps->[0]->once(revoke => sub { my $e = shift; $args = shift });

  $t->delete_ok(url $auth_url, '/grant/optimus/open/matrix')
    ->status_is(200)->content_is('ok');
    
  is $args->{admin},    'primus',  'admin = primus';
  is $args->{group},    'optimus', 'group = optimus';
  is $args->{action},   'open',    'action = open';
  is $args->{resource}, 'matrix',  'resource = matrix';
};

do {
  # / (accounts): god
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(403)
    for qw( optimus grimlock starscream megatron skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(200)
    for qw( primus unicron );

  # /altmode (transform): public
  $t->get_ok(url $url, "/authz/user/$_/transform/altmode")->status_is(200)
    for qw( optimus grimlock starscream megatron skylynks swoop primus unicron );

  # /red (color): autobot
  # /purple (color): decepticon
  $t->get_ok(url $url, "/authz/user/$_/color/red")->status_is(200)
    for qw( optimus grimlock skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/color/purple")->status_is(200)
    for qw( starscream megatron );
    
  # /battle (retreat): megatron
  $t->get_ok(url $url, '/authz/user/megatron/retreat/battle')->status_is(200);
  $t->get_ok(url $url, "/authz/user/$_/retreat/battle")->status_is(403)
    for qw( optimus grimlock starscream skylynks swoop primus unicron );

  # /matrix (open): optimus
  $t->get_ok(url $url, "/authz/user/$_/open/matrix")->status_is(403)
    for qw( optimus megatron grimlock starscream skylynks swoop primus unicron );
};

$t->delete_ok(url $auth_url, '/grant/megatron/retreat/battle')->status_is(200);

do {
  # / (accounts): god
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(403)
    for qw( optimus grimlock starscream megatron skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(200)
    for qw( primus unicron );

  # /altmode (transform): public
  $t->get_ok(url $url, "/authz/user/$_/transform/altmode")->status_is(200)
    for qw( optimus grimlock starscream megatron skylynks swoop primus unicron );

  # /red (color): autobot
  # /purple (color): decepticon
  $t->get_ok(url $url, "/authz/user/$_/color/red")->status_is(200)
    for qw( optimus grimlock skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/color/purple")->status_is(200)
    for qw( starscream megatron );
    
  # /battle (retreat): megatron
  $t->get_ok(url $url, "/authz/user/$_/retreat/battle")->status_is(403)
    for qw( megatron optimus grimlock starscream skylynks swoop primus unicron );

  # /matrix (open): optimus
  $t->get_ok(url $url, "/authz/user/$_/open/matrix")->status_is(403)
    for qw( optimus megatron grimlock starscream skylynks swoop primus unicron );
};

$t->delete_ok(url $auth_url, '/grant/autobot/color/red')->status_is(200);

do {
  # / (accounts): god
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(403)
    for qw( optimus grimlock starscream megatron skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(200)
    for qw( primus unicron );

  # /altmode (transform): public
  $t->get_ok(url $url, "/authz/user/$_/transform/altmode")->status_is(200)
    for qw( optimus grimlock starscream megatron skylynks swoop primus unicron );

  # /red (color): autobot
  # /purple (color): decepticon
  $t->get_ok(url $url, "/authz/user/$_/color/red")->status_is(403)
    for qw( optimus grimlock skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/color/purple")->status_is(200)
    for qw( starscream megatron );
    
  # /battle (retreat): megatron
  $t->get_ok(url $url, "/authz/user/$_/retreat/battle")->status_is(403)
    for qw( megatron optimus grimlock starscream skylynks swoop primus unicron );

  # /matrix (open): optimus
  $t->get_ok(url $url, "/authz/user/$_/open/matrix")->status_is(403)
    for qw( optimus megatron grimlock starscream skylynks swoop primus unicron );
};

$t->delete_ok(url $auth_url, '/grant/decepticon/color/purple')->status_is(200);

do {
  # / (accounts): god
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(403)
    for qw( optimus grimlock starscream megatron skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(200)
    for qw( primus unicron );

  # /altmode (transform): public
  $t->get_ok(url $url, "/authz/user/$_/transform/altmode")->status_is(200)
    for qw( optimus grimlock starscream megatron skylynks swoop primus unicron );

  # /red (color): autobot
  # /purple (color): decepticon
  $t->get_ok(url $url, "/authz/user/$_/color/red")->status_is(403)
    for qw( optimus grimlock skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/color/purple")->status_is(403)
    for qw( starscream megatron );
    
  # /battle (retreat): megatron
  $t->get_ok(url $url, "/authz/user/$_/retreat/battle")->status_is(403)
    for qw( megatron optimus grimlock starscream skylynks swoop primus unicron );

  # /matrix (open): optimus
  $t->get_ok(url $url, "/authz/user/$_/open/matrix")->status_is(403)
    for qw( optimus megatron grimlock starscream skylynks swoop primus unicron );
};

$t->delete_ok(url $auth_url, "/grant/public/transform/altmode")->status_is(200);

do {
  # / (accounts): god
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(403)
    for qw( optimus grimlock starscream megatron skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/accounts/user")->status_is(200)
    for qw( primus unicron );

  # /altmode (transform): public
  $t->get_ok(url $url, "/authz/user/$_/transform/altmode")->status_is(403)
    for qw( optimus grimlock starscream megatron skylynks swoop primus unicron );

  # /red (color): autobot
  # /purple (color): decepticon
  $t->get_ok(url $url, "/authz/user/$_/color/red")->status_is(403)
    for qw( optimus grimlock skylynks swoop );
  $t->get_ok(url $url, "/authz/user/$_/color/purple")->status_is(403)
    for qw( starscream megatron );
    
  # /battle (retreat): megatron
  $t->get_ok(url $url, "/authz/user/$_/retreat/battle")->status_is(403)
    for qw( megatron optimus grimlock starscream skylynks swoop primus unicron );

  # /matrix (open): optimus
  $t->get_ok(url $url, "/authz/user/$_/open/matrix")->status_is(403)
    for qw( optimus megatron grimlock starscream skylynks swoop primus unicron );
};

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
optimus:mpmPbOhUeIt1E
primus:Bv4QLfsRAW.pY
grimlock:uogf5/viZOdDA
starscream:tCp3KDOivhlzo
megatron:8n2eh8qdddqdI
skylynks:wPCaIh1gAmL8w
swoop:G/LxEEIR9PsBI
unicron:g8qCjd1FUZUEk


@@ var/data/group
autobot: optimus,grimlock,skylynks,swoop
decepticon: starscream,megatron
public: *
god: primus,unicron


@@ var/data/host
# empty


@@ var/data/resource
/ (accounts): god
/altmode (transform): public
/red (color): autobot
/purple (color): decepticon
/battle (retreat): megatron
/matrix (open): optimus

