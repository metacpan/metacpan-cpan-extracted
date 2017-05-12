# ============
# retrieval.t
# ============
use Mojo::Base -strict;
use Test::More;

use Mojar::Google::Analytics;
use Mojar::Util 'slurp_chomped';
use Mojo::File 'path';

plan skip_all => 'set TEST_ACCESS to enable this test (developer only!)'
  unless $ENV{TEST_ACCESS};

my ($user, $pk, $profile);

subtest q{Setup} => sub {
  $user = slurp_chomped 'data/auth_user.txt';
  ok $user, 'user';
  $pk = path('data/privatekey.pem')->slurp;
  ok $pk, 'pk';
  $profile = slurp_chomped 'data/profile.txt';
  ok $profile, 'profile';
};

my ($analytics, $res);

subtest q{Basics} => sub {
  ok $analytics = Mojar::Google::Analytics->new(
    auth_user => $user,
    private_key => $pk,
    profile_id => $profile
  ), 'new(profile_id => ..)';

  ok $analytics->req(
    metrics => [qw(visits)]
  ), 'req(..)';
};

subtest q{Bad Auth} => sub {
  $analytics->{auth_user} .= 'X';
  delete $analytics->{jwt};
  eval {
    $analytics->renew_token;
    fail 'Threw exception';
  }
  or do {
    my $e = $@ // '';
    like $e, qr/401 error:/, 'right code';
    like $e, qr/invalid_client/, 'right message';
  };
  $analytics->{auth_user} = $user;
  delete $analytics->{jwt};
  ok $analytics->renew_token, 'renewed token';
};

subtest q{Bad Auth 2} => sub {
  $analytics->{grant_type} .= 'X';
  delete $analytics->{jwt};
  eval {
    $analytics->renew_token;
    fail 'Threw exception';
  }
  or do {
    my $e = $@ // '';
    like $e, qr/400 error:/, 'right code';
    like $e, qr/unsupported_grant_type/, 'right message';
  };
  $analytics->{grant_type} =~ s/X$//;
  delete $analytics->{jwt};
  ok $analytics->renew_token, 'renewed token';
};

subtest q{token} => sub {
  eval {
    ok $analytics->has_valid_token, 'has_valid_token';
  }
  or do {
    my $e = $@;
    diag sprintf "user: [%s]\npk: [%s]\nprofile: [%s]\nerror: %s",
        $user, $pk, $profile, $e;
  };
  ok $analytics->renew_token, 'renew_token';
};

subtest q{fetch} => sub {
  eval {
    ok $res = $analytics->fetch, 'fetch';
  }
  or diag sprintf "profile: [%s]\nerror: %s",
      $profile, $analytics->res->error->{message} // '';
  ok $res->success, 'success';
};

subtest q{Result set} => sub {
  ok $analytics->req(
    dimensions => [qw(pagePath)],
    metrics => [qw(visitors newVisits visits bounces timeOnSite entrances
        pageviews uniquePageviews timeOnPage exits)],
    sort => 'pagePath',
    start_index => 1,
    max_results => 5
  ), 'req(..)';
  ok $res = $analytics->fetch, 'fetch';
  ok $res->success, 'success';

  ok $analytics->req(
    start_index => 6,
    max_results => 5
  ), 'req(..)';
  ok $res = $analytics->fetch, 'fetch';
  ok $res->success, 'success';

  ok $res->rows, 'got rows';
  ok scalar(@{$res->rows}), 'got some rows';
  cmp_ok scalar(@{$res->rows}), '==', 5, 'got correct qty rows';
  cmp_ok scalar(@{$res->columns}), '==', 11, 'got correct qty columns';
};

subtest q{error} => sub {
  ok $analytics->req(
    metrics => [qw(voots)]
  ), 'req(..)';
  eval {
    $res = $analytics->fetch;
  };
  ok ! $res, 'returned false';
  ok $res = $analytics->res, 'got stored res';
  ok $analytics->res->error, 'error';
  ok ! $res->success, 'not success';
  like $res->message, qr/unknown metric/i, 'message';
  like $res->message, qr/voots/, 'correct identification';
};

done_testing();
