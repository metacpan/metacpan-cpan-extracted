#!perl

# pragmas
use 5.10.0;
use strict;
use warnings;

# imports
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::More;

eval {
  use Mock::HTTPClient;
};
die "Mock load exception $@" if $@; 

# load test
use Net::Pushover;


# new object
subtest 'transport success' => sub {
  my $p = Net::Pushover->new(
    user  => 'xxxxxxxxxxxxxxx', 
    token => 'xxxxxxxxxxxxxxx', 
    _ua   => Mock::HTTPClient->new(
      status  => '200 OK', 
      content => '{"status":1,"request":"d5b4d646a8c23ccefcbdb53220930c9b"}'
    )
  );

  my $res = $p->message( text => 'Test message' );

  # transport test
  ok $res; 
  ok $res->{request}; 
  is $res->{status}, 1; 
};


# new object
subtest 'transport error' => sub {
  my $p = Net::Pushover->new(
    user  => 'xxxxxxxxxxxxxxx', 
    token => 'xxxxxxxxxxxxxxx', 
    _ua   => Mock::HTTPClient->new(
      status  => '400 Bad Request', 
      content => '{"token":"invalid","errors":["application token is invalid"],"status":0,"request":"564a7165072d807c1be9d6f13ea8f3c1"}'
    )
  );

  my $res = $p->message( text => 'Test message' );

  # transport test
  ok $res; 
  is $res->{status}, 0; 
  is $res->{errors}->[0], 'application token is invalid'; 
};



done_testing();
