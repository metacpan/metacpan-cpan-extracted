use strict;
use warnings;
use Test::More tests => 1;

eval q{
  use PlugAuth::Client::Tiny;
};
die $@ if $@;

my $client = PlugAuth::Client::Tiny->new;

eval { $client->authz('foo', 'bar', '/baz') };
like $@, qr/Could not connect/, "threw an exception";

package HTTP::Tiny;

BEGIN { $INC{'HTTP/Tiny.pm'} = __PACKAGE__ };

sub new { bless {}, 'HTTP::Tiny' }

sub get 
{
  return { 
    status => 599, 
    content => "Could not connect to 'localhost:3000': IO::Socket::INET: connect: Connection refused",
  };
}