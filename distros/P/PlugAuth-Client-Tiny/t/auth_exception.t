use strict;
use warnings;
use Test::More tests => 2;

eval q{
  use PlugAuth::Client::Tiny;
};

my $last_url;

my $client = PlugAuth::Client::Tiny->new;

eval { $client->auth('user', 'pass') };
like $@, qr/Could not connect/, "threw an exception";

is $last_url, 'http://localhost:3000/auth', 'url = http://localhost:3000/auth';

package HTTP::Tiny;

BEGIN { $INC{'HTTP/Tiny.pm'} = __PACKAGE__ };

sub new { bless {}, 'HTTP::Tiny' }

sub get 
{
  my($self, $url, $options) = @_;
  $last_url = $url;
  return { 
    status => 599, 
    content => "Could not connect to 'localhost:3000': IO::Socket::INET: connect: Connection refused",
  };
}
