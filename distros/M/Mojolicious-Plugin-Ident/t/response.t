use strict;
use warnings;
use Test::More tests => 14;
use Mojolicious::Plugin::Ident::Response;

do {
  my $ident = eval {
    Mojolicious::Plugin::Ident::Response->new(
      "56192 , 113 : USERID : AwesomeOS :foo"
    );
  };
  diag $@ if $@;
  $ident->{remote_address} = '127.0.0.1';

  isa_ok $ident, 'Mojolicious::Plugin::Ident::Response';
  is eval { $ident->username         }, 'foo',       'username = foo';
  diag $@ if $@;
  is eval { $ident->os               }, 'AwesomeOS', 'os = AwesomeOS';
  diag $@ if $@;
  is eval { $ident->{remote_address} }, '127.0.0.1', 'remote_address = 127.0.0.1';
};

ok eval { Mojolicious::Plugin::Ident::Response->_setup; 1 }, '_setup';

my $user = Mojolicious::Plugin::Ident::Response->_server_user_name;
my $uid  = Mojolicious::Plugin::Ident::Response->_server_user_uid;

ok($user, "has server username $user");
SKIP: {
  skip "no uid on windows", 1 if $^O eq 'MSWin32';
  like($uid, qr{^\d+$}, "has server uid $uid");
};

is eval { 
  my $res = Mojolicious::Plugin::Ident::Response->new( "56192 , 113 : USERID : AwesomeOS :$user");
  $res->{remote_address} = '127.0.0.1';
  $res->same_user 
}, 1, "same user based on username is good";
diag $@ if $@;

is eval {
  my $res = Mojolicious::Plugin::Ident::Response->new( "56192 , 113 : USERID : AwesomeOS :${user}bogus");
  $res->{remote_address} = '127.0.0.1';
  !$res->same_user 
}, 1, "same user based on username is bad";
diag $@ if $@;

is eval {
  my $res = Mojolicious::Plugin::Ident::Response->new( "56192 , 113 : USERID : AwesomeOS :$user");
  $res->{remote_address} = '1.2.3.4';
  !$res->same_user
}, 1, "same user based on hostname is bad";
diag $@ if $@;

SKIP: {
  skip "no uid on windows", 3 if $^O eq 'MSWin32';

  is eval { 
    my $res = Mojolicious::Plugin::Ident::Response->new( "56192 , 113 : USERID : AwesomeOS :$uid");
    $res->{remote_address} = '127.0.0.1';
    $res->same_user 
  }, 1, "same user based on uid is good";
  diag $@ if $@;

  is eval { 
    my $res = Mojolicious::Plugin::Ident::Response->new( "56192 , 113 : USERID : AwesomeOS :" . ($uid+20));
    $res->{remote_address} = '127.0.0.1';
    !$res->same_user 
  }, 1, "same user based on uid is bad";
  diag $@ if $@;

  is eval {
    my $res = Mojolicious::Plugin::Ident::Response->new( "56192 , 113 : USERID : AwesomeOS :$uid" );
    $res->{remote_address} = '1.2.3.4';
    !$res->same_user }, 1, "same user based on hostname is bad (uid)";
  diag $@ if $@;
};

pass "it isn't lucky to have 13 tests.";
