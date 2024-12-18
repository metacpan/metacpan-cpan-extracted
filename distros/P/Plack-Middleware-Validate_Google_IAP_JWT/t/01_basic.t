#!/usr/bin/env perl
use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

{
  my $app = builder {
    enable "Validate_Google_IAP_JWT", want_hd => "example.com"
      , guest_subpath => "/guest/";
    sub {
      my ($env) = @_;
      return [200, [], ["OK"]];
    };
  };

  test_psgi app => $app, client => sub {
    my ($cb) = @_;

    {
      my $res = $cb->(GET "http://localhost/guest/");
      is $res->code, 200, "/guest/ is visible";
    }

    {
      my $res = $cb->(GET "http://localhost/");
      is $res->code, 403, "/ is forbidden";
    }

    {
      my $req = GET "http://localhost/"
        , 'x-goog-iap-jwt-assertion' => "fake.foo.bar";

      my $res = $cb->($req);

      is $res->code, 400, "/ with fake JWT is forbidden";

      like $res->content, qr/JWS: /, "JWS error";
    }

    my $sampleFn = "$FindBin::Bin/sample.jwt";

    SKIP: {
      skip "sample.jwt is not there", 2 unless -e $sampleFn;

      my $jwt = do {
        open my $fh, '<', $sampleFn;
        local $/;
        <$fh>
      };

      my $req = GET "http://localhost/"
        , 'x-goog-iap-jwt-assertion' => $jwt;

      my $res = $cb->($req);

      is $res->code, 403, "/ with expired JWT is forbidden";

      like $res->content, qr/JWT: \S+ claim check failed/, "some claim check is failed";
    }
  };
}

done_testing;
