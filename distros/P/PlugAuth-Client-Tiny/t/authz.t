use strict;
use warnings;
use Test::More tests => 3;

eval q{
  use PlugAuth::Client::Tiny;
};
die $@ if $@;

my $client = PlugAuth::Client::Tiny->new;

ok eval { $client->authz('admin', 'accounts', '/user') }, "admin can accounts on /user";
diag $@ if $@;
ok eval { $client->authz('admin', 'accounts', 'user') }, "admin can accounts on /user";
diag $@ if $@;

ok eval { ! $client->authz('bogus', 'accounts', '/user') }, "bogus can NOT accounts on /";
diag $@ if $@;

package HTTP::Tiny;

BEGIN { $INC{'HTTP/Tiny.pm'} = __PACKAGE__ };

sub new { bless {}, 'HTTP::Tiny' }

sub get 
{
  my($self, $url, $options) = @_;
  if($url eq 'http://localhost:3000/authz/user/admin/accounts/user')
  {
    return { status => 200 }
  }
  else
  {
    return { status => 403 }
  }
}