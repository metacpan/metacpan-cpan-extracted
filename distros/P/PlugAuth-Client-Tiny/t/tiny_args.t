use strict;
use warnings;
use Test::More tests => 4;

eval q{ use PlugAuth::Client::Tiny };

my $http;

my $client = eval { 
  PlugAuth::Client::Tiny->new( 
    foo => 1, 
    bar => 2, 
    url => "http://whatever.com",
  );
};
diag $@ if $@;
isa_ok $client, 'PlugAuth::Client::Tiny';

is $http->{foo}, 1,     'foo = 1';
is $http->{bar}, 2,     'bar = 2';
is $http->{url}, undef, 'url = undef';

package HTTP::Tiny;

BEGIN { $INC{'HTTP/Tiny.pm'} = __FILE__ }

sub new {
  my $class = shift;
  $http = bless { @_ }, $class;
}


