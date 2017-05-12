use strict;
use warnings;
use Plack::Test;
use Test::More;
use Test::Deep;
use Plack::Middleware::LogWarn;
use HTTP::Request::Common;

my $basic_warn;

my $app = sub {
  my $env = shift;
  
  #make the logger dump everything into our test var
  local $env->{'psgix.logger'} = sub {
    $basic_warn = shift;
  };
  #warn out something important to be logged
  warn 'a voice crying out in the wilderness';
  
  return [ 200, [], [] ];
};

#wrap with the default config
$app = Plack::Middleware::LogWarn->wrap($app);

test_psgi $app, sub {
  my $cb = shift;
  my $res = $cb->(GET "/");
  
  my $expected = {
    level => 'warn',
    message => re('a voice crying out in the wilderness'),
  };
  
  cmp_deeply (
    $basic_warn,
    $expected,
    'warnings correct with default config'
  );
};

my $configured_warn;

my $configured_app = sub {
  my $env = shift;

  #make the logger dump everything into our test var
  local $env->{'psgix.logger'} = sub {
    $configured_warn = shift;
  };  

  #warn out something important to be logged
  warn 'a prophet is not welcomed in his own country';
  
  return [ 200, [], [] ];  
};

#wrap with a different logger (route to a var)
$configured_app = Plack::Middleware::LogWarn->wrap($configured_app, logger => sub { $configured_warn = shift });

test_psgi $configured_app, sub {
  my $cb = shift;
  my $res = $cb->(GET "/");
  
  like $configured_warn, qr[a prophet is not welcomed in his own country], 'warnings correct with custom logger';
};

done_testing;