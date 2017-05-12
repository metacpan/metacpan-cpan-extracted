# ============
# auth.t
# ============
use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojar::Auth::Jwt;
use Mojo::File 'path';

my $jwt;

subtest q{Basics} => sub {
  ok $jwt = Mojar::Auth::Jwt->new, 'new()';
};

sub _test {
  my $s = {
    typ => 'JWT',
    alg => 'RS256'
  };
  my $t = Mojo::JSON->new->encode($s);
  require Data::Dump;
  say Data::Dump::dump($t);
  say Data::Dump::dump(Mojo::JSON->new->decode($t));
  say MIME::Base64::encode_base64url($t);
  my $a = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9';
  say Data::Dump::dump(Mojo::JSON->new->decode(MIME::Base64::decode_base64url($a)));
}

subtest q{header} => sub {
  ok $jwt->header, 'Got header';
  is_deeply $jwt->demogrify($jwt->header),
    $jwt->demogrify(q{eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9}),
    'header perfect';

  ok $jwt->header(alg => 'RS64'), 'Set header(hash)';
  is_deeply $jwt->demogrify($jwt->header),
    $jwt->demogrify(q{eyJhbGciOiJSUzY0IiwidHlwIjoiSldUIn0}),
    'Got header (hash)';

  ok $jwt->header(alg => 'RS256'), 'Set header(hash)';
  is_deeply $jwt->demogrify($jwt->header),
    $jwt->demogrify(q{eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9}),
    'header perfect again';
};

subtest q{body} => sub {
  eval { $jwt->body }
  or do {
    ok $@, 'Exception from get';
  };
  like $@, qr/^Missing required field /, 'Caught missing field(s)';

  ok $jwt
    ->iss(q{761326798069-r5mljlln1rd4lrbhg75efgigp36m78j5@developer.gserviceaccount.com})
    ->scope(q{https://www.googleapis.com/auth/prediction})
    ->iat(q{1328550785})
    ->exp(q{1328554385}), 'Sets';

  ok $jwt->body, 'Got body';
  is_deeply $jwt->demogrify($jwt->body),
    $jwt->demogrify(q{eyJpc3MiOiI3NjEzMjY3OTgwNjktcjVtbGpsbG4xcmQ0bHJiaGc3NWVmZ}
    .q{2lncDM2bTc4ajVAZGV2ZWxvcGVyLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJzY29wZSI6Imh0d}
    .q{HBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvcHJlZGljdGlvbiIsImF1ZCI6Imh0dHBzO}
    .q{i8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi90b2tlbiIsImV4cCI6MTMyODU1NDM4N}
    .q{SwiaWF0IjoxMzI4NTUwNzg1fQ}),
    'body perfect';
};

subtest q{signature} => sub {
  eval { $jwt->signature }
  or do {
    ok $@, 'Exception from get';
  };
  like $@, qr/^Missing required field /, 'Caught missing field(s)';
};

subtest q{decode} => sub {
  ok $jwt = Mojar::Auth::Jwt->decode(q{eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.}
    .q{eyJpc3MiOiI3NjEzMjY3OTgwNjktcjVtbGpsbG4xcmQ0bHJiaGc3NWVmZ2lncDM2bTc4ajVA}
    .q{ZGV2ZWxvcGVyLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJzY29wZSI6Imh0dHBzOi8vd3d3Lmdv}
    .q{b2dsZWFwaXMuY29tL2F1dGgvcHJlZGljdGlvbiIsImF1ZCI6Imh0dHBzOi8vYWNjb3VudHMu}
    .q{Z29vZ2xlLmNvbS9vL29hdXRoMi90b2tlbiIsImV4cCI6MTMyODU1NDM4NSwiaWF0IjoxMzI4}
    .q{NTUwNzg1fQ.ixOUGehweEVX_UKXv5BbbwVEdcz6AYS-6uQV6fGorGKrHf3LIJnyREw9evE-g}
    .q{s2bmMaQI5_UbabvI4k-mQE4kBqtmSpTzxYBL1TCd7Kv5nTZoUC1CmwmWCFqT9RE6D7XSgPUh}
    .q{_jF1qskLa2w0rxMSjwruNKbysgRNctZPln7cqQ}), 'decode OAuth2 example';
  is_deeply $jwt, Mojar::Auth::Jwt->new(
      typ => q{JWT},
      alg => q{RS256},
      iss => q{761326798069-r5mljlln1rd4lrbhg75efgigp36m78j5}
        .q{@developer.gserviceaccount.com},
      scope => q{https://www.googleapis.com/auth/prediction},
      aud => q{https://accounts.google.com/o/oauth2/token},
      iat => q{1328550785},
      exp => q{1328554385}
    ), 'Decoded object agrees';
};

SKIP: {
  skip 'set TEST_KEY to enable this test (developer only!)', 1
    unless $ENV{TEST_KEY};
subtest q{Roundtrip encode->decode} => sub {
  my $jwt2;
  ok $jwt2 = $jwt->decode($jwt->encode(
      private_key => path('data/privatekey.pem')->slurp)), 'decode(encode())';
  delete @$jwt{qw( header body signature json cipher private_key )};
  is_deeply $jwt2, $jwt, 'Round trip';
};
};

done_testing();
