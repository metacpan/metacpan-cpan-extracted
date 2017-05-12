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
use_ok 'Net::Pushover';


# new object
my $p;
subtest 'new object' => sub {
  eval { 
    # object with mocked http client
    $p = Net::Pushover->new( 
      _ua => Mock::HTTPClient->new(
        status  => '200 OK', content => 'All ok'
      ) 
    ); 
  };
  ok !$@, 'new object';
  isa_ok $p, 'Net::Pushover';
};


# methods test
subtest 'methods test' => sub {
  can_ok $p, qw/new _ua token user  message/;
};


# auth validation is required
subtest 'auth validation fail test' => sub {
  # token error
  eval{ $p->_auth_validation };

  ok $@;
  like $@, qr#Error: token is undefined#;

  # user error
  $p->token('xxxxxxxxxx');
  eval{ $p->_auth_validation };

  ok $@;
  like $@, qr#Error: user is undefined#;
};


# auth validation pass
subtest 'auth validation ok test' => sub {
  $p->user('xxxxxxxxxxxxxx');
  $p->token('xxxxxxxxxxxxxx');

  ok $p->_auth_validation;
  is $p->user,  'xxxxxxxxxxxxxx';
  is $p->token, 'xxxxxxxxxxxxxx';
};


# message require validation test
subtest 'auth validation ok test' => sub {
  eval { $p->message };

  ok $@;
  like $@, qr#Field text is required for message body#;
};


done_testing();
