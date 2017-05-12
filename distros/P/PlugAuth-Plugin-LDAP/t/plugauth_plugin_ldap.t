use strict;
use warnings;
use 5.010;
use Test::Clustericious::Cluster;
use Test::More tests => 16;

my $cluster = Test::Clustericious::Cluster->new;

$cluster->create_cluster_ok('PlugAuth');
my $t = $cluster->t;

our $net_ldap_saw_user;
our $net_ldap_saw_password;

my($url) = map { $_->clone } @{ $cluster->urls };

sub url ($$@) {
  my($url, $path,@rest) = @_;
  $url = $url->clone;
  $url->path($path);
  wantarray ? ($url, @rest) : $url;
}

# good user, good password
$url->userinfo('optimus:matrix');
$t->get_ok(url $url, "/auth")
  ->status_is(200)
  ->content_is("ok", 'auth succeeded');

is $net_ldap_saw_user, 'optimus', 'user = optimus';
is $net_ldap_saw_password, 'matrix', 'password = matrix';

# good user, bad password
$url->userinfo('optimus:badguess');
$t->get_ok(url $url, "auth")
  ->status_is(403)
  ->content_is("not ok", 'auth succeeded');

is $net_ldap_saw_user, 'optimus', 'user = optimus';
is $net_ldap_saw_password, 'badguess', 'password = badguess';

# good user, bad password
$url->userinfo('bogus:matrix');
$t->get_ok(url $url, "auth")
  ->status_is(403)
  ->content_is("not ok", 'auth succeeded');

is $net_ldap_saw_user, 'bogus', 'user = bogus';
is $net_ldap_saw_password, 'matrix', 'password = matrix';

__DATA__

@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>

% for my $name (qw( group host resource ) ) {
%   my $file = file home, $name;
%   $file->spew('');
<%= $name %>_file: <%= $file %>
% }

% do {
%   my $file = file home, 'user';
%   $file->spew("optimus:RjLie.H/DrOHE\n");
user_file: <%= $file %>
% };

ldap:
  authoritative: 1
  dn: 'uid=%s, ou=people, dc=users, dc=example, dc=com'
  server: ldap://192.168.1.1:389


@@ lib/Net/LDAP.pm
package Net::LDAP;

use strict;
use warnings;
use Net::LDAP::Message;

sub new
{
  bless {}, 'Net::LDAP';
}

sub bind
{
  my($self, $dn, %args) = @_;

  if($dn =~ /^uid=([a-z]+), ou=people, dc=users, dc=example, dc=com$/)
  { $main::net_ldap_saw_user = $1 }
  else
  { $main::net_ldap_saw_user = '---' }
  $main::net_ldap_saw_password = $args{password};

  my $code = !($main::net_ldap_saw_user eq 'optimus' && $main::net_ldap_saw_password eq 'matrix');
  bless { code => $code }, 'Net::LDAP::Message';
}

package Net::LDAP::Message;

no warnings;
sub code { shift->{code} }
sub error { shift->{code} ? 'unauthorized' : 'authorized' }

1;
