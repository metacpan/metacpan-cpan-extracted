use utf8;

use strict;
use warnings;

use Test::Most;

use HTTP::Request::Common;
use HTTP::Status qw/ :constants /;
use JSON::MaybeXS qw/ decode_json /;
use Plack::Builder;
use Plack::Test;

my $Orig;

my $handler = builder {

    enable "TrafficAdvice",
      data => [
        {
            user_agent => "prefetch-proxy",
            disallow   => JSON::MaybeXS->true,
        }
      ];

};

test_psgi
  app    => $handler,
  client => sub {
    my ($cb) = @_;

    my $req = GET '/.well-known/traffic-advice';
    my $res = $cb->($req);

    is $res->code, HTTP_OK, 'HTTP OK';
    is $res->content_type, 'application/trafficadvice+json', 'Content-Type';

    my $data = decode_json( $res->decoded_content );

    cmp_deeply $data,
      [
        {
            user_agent => "prefetch-proxy",
            disallow   => bool(1),
        }
      ],
      "expected data";

  };

done_testing;
