use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

use Plack::Middleware::OIDC::Redirect;

my $url = 'https://provider.example.com/authorize?client_id=my-app-id&state=abc';

subtest 'as_psgi() builds a PSGI redirect response' => sub {
  my $redirect = Plack::Middleware::OIDC::Redirect->new(url => $url);

  can_ok($redirect, qw(url as_psgi));
  is($redirect->url, $url, 'url() returns the url');

  my $psgi = $redirect->as_psgi();
  is(ref $psgi, 'ARRAY', 'as_psgi() returns a PSGI response (arrayref)');
  is($psgi->[0], 302, 'status is 302');
  is_deeply({ @{ $psgi->[1] } }, { Location => $url }, 'Location header is the url, and only that header');
};

done_testing();
