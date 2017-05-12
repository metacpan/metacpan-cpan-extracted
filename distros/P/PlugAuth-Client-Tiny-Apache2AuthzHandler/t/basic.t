use strict;
use warnings;
use 5.012;
use Test::More tests => 4;

eval {
  # create some mock classes
  
  package PlugAuth::Client::Tiny;
  
  sub new
  {
    my($class) = @_;
    bless {}, $class;
  }
  
  sub authz
  {
    my($self, $user, $method, $resource) = @_;
    !! ($user eq 'root' && $method eq 'GET' && $resource eq '/protected')
    || ($user eq 'root' && $method eq 'GET' && $resource eq '/myprefix/private');
  }
  
  $INC{'PlugAuth/Client/Tiny.pm'} = __FILE__;
  
  package Apache2::Access;
  
  $INC{'Apache2/Access.pm'} = __FILE__;
  
  package Apache2::Const;
  
  use constant OK => 200;
  use constant HTTP_UNAUTHORIZED => 402;
  
  $INC{'Apache2/Const.pm'} = __FILE__;
  
  package Apache2::RequestRec;
  
  sub new
  {
    my($class, %args) = @_;
    bless {
      user   => $args{user},
      method => $args{method} // (die "must define method"),
      uri    => $args{uri}    // (die "must define uri"),
      fail   => 0,
    }, $class;
  }
  
  sub user   { shift->{user}   }
  sub method { shift->{method} }
  sub uri    { shift->{uri}    }
  
  sub note_basic_auth_failure
  {
    shift->{fail} = 1;
  }
  
  $INC{'Apache2/RequestRec.pm'} = __FILE__;
  
  package Apache2::RequestUtil;
  
  $INC{'Apache2/RequestUtil.pm'} = __FILE__;
};

die $@ if $@;

require_ok 'PlugAuth::Client::Tiny::Apache2AuthzHandler';

subtest 'user is noth authorized' => sub {
  plan tests => 2;
  
  my $req = Apache2::RequestRec->new(
    user   => 'foo',
    method => 'GET',
    uri    => '/whatever',
  );
  
  my $ret = PlugAuth::Client::Tiny::Apache2AuthzHandler::handler($req);
  
  is $ret, Apache2::Const::HTTP_UNAUTHORIZED, 'Handler returns HTTP_UNAUTHORIZED';
  is $req->{fail}, 1,                         'noted failure';
  
};

subtest 'user is authorized' => sub {
  plan tests => 2;

  my $req = Apache2::RequestRec->new(
    user   => 'root',
    method => 'GET',
    uri    => '/protected',
  );
  
  my $ret = PlugAuth::Client::Tiny::Apache2AuthzHandler::handler($req);
  
  is $ret,          Apache2::Const::OK, 'Handler returns OK';
  is $req->{fail},  0,                  'No noted failure';

};

subtest 'prefix' => sub {

  local $ENV{PLUGAUTH_PREFIX} = '/myprefix';

  my $req = Apache2::RequestRec->new(
    user   => 'root',
    method => 'GET',
    uri    => '/private',
  );

  my $ret = PlugAuth::Client::Tiny::Apache2AuthzHandler::handler($req);
  
  is $ret,          Apache2::Const::OK, 'Handler returns OK';
  is $req->{fail},  0,                  'No noted failure';
};
