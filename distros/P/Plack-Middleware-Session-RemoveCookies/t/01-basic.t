use strict;
use warnings;
use Test::More;
use Plack::Builder;

my @tests = (
  {
    key => qr{plack_session}i,
    env => {
      HTTP_COOKIE => 'plack_session=e5xmy5zk0ci3it3nxcmv1fvx; SearchVals=a9f44125-bf51-4a19-8680-6f0c40a9dfe2',
    },
  },
);

foreach my $test (@tests) {
  my ( $key, $test_env ) = @$test{qw(key env)};
  my $app = builder {
    enable 'Session::RemoveCookies',
      key => $key;
    enable sub {
      my $app = shift;
      sub {
        my $env = shift;
	ok($env->{'HTTP_COOKIE'} !~ $key);
	ok($env->{'HTTP_COOKIE'});
	ok($env->{'plack.cookie.string'});
	is($env->{'HTTP_COOKIE'}, $env->{'plack.cookie.string'});
        return $app->($env);
      };
    };
    sub { [ 200, 'Content-Type' => 'text/plain', ['Test'] ] }
  };
  my $res = $app->($test_env);
  ok($res->[0] == 200);
}

done_testing;
