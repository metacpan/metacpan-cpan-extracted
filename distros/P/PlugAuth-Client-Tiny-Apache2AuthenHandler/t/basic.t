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
  
  sub auth
  {
    my($self, $user, $pass) = @_;
    !!($user eq 'root' && $pass eq 'default');
  }

  $INC{'PlugAuth/Client/Tiny.pm'} = __FILE__;
  
  package Apache2::Access;
  
  $INC{'Apache2/Access.pm'} = __FILE__;
  
  package Apache2::RequestUtil;
  
  $INC{'Apache2/RequestUtil.pm'} = __FILE__;
  
  package Apache2::Const;
  
  use constant OK => 200;
  use constant HTTP_UNAUTHORIZED => 402;

  $INC{'Apache2/Const.pm'} = __FILE__;

  package Apache2::RequestRec;
  
  sub new
  {
    my($class, %args) = @_;
    bless {
      user   => $args{user}   // 'foo',
      pass   => $args{pass}   // 'bar',
      status => $args{status} // Apache2::Const::OK,
      fail   => 0,
    }, $class;
  }
  
  sub get_basic_auth_pw
  {
    my($self) = @_;
    ($self->{status}, $self->{pass});
  }
  
  sub user                    { shift->{user} }
  sub note_basic_auth_failure { shift->{fail} = 1 }
  
  $INC{'Apache2/RequestReq.pm'} = __FILE__;
};

die $@ if $@;

require_ok 'PlugAuth::Client::Tiny::Apache2AuthenHandler';

subtest 'status is not okay' => sub {
  plan tests => 2;

  my $req = Apache2::RequestRec->new(
    user   => 'foo',
    pass   => 'bar',
    status => 0,
  );
  
  my $ret = PlugAuth::Client::Tiny::Apache2AuthenHandler::handler($req);

  is $ret,          0, 'Handler returns exisiting status';
  is $req->{fail},  0, 'No noted failure';

};

subtest 'user is not authenticated' => sub {
  plan tests => 2;

  my $req = Apache2::RequestRec->new(
    user   => 'foo',
    pass   => 'bar',
  );
  
  my $ret = PlugAuth::Client::Tiny::Apache2AuthenHandler::handler($req);

  is $ret,          Apache2::Const::HTTP_UNAUTHORIZED, 'Handler returns HTTP_UNAUTHORIZED';
  is $req->{fail},  1,                                 'noted failure';
  
};

subtest 'user is authenticated' => sub {
  plan tests => 2;

  my $req = Apache2::RequestRec->new(
    user   => 'root',
    pass   => 'default',
  );
  
  my $ret = PlugAuth::Client::Tiny::Apache2AuthenHandler::handler($req);

  is $ret,          Apache2::Const::OK, 'Handler returns OK';
  is $req->{fail},  0,                  'No noted failure';
};
