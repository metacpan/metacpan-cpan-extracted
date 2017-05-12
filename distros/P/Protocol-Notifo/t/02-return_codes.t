#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use Protocol::Notifo;

my $n = Protocol::Notifo->new(user => 'me', api_key => 'mini_me');

my @test_cases = (
  [ { http_response_code => 401,
      http_status_line   => '402 OK OK OK',
      http_body =>
        '{ "status": "error", "response_code": 1100, "response_message": "An error occurred" }'
    },
    { http_response_code => 401,
      http_status_line   => '402 OK OK OK',
      status             => "error",
      response_code      => 1100,
      response_message   => "An error occurred",
      other              => {}
    },
  ],
  [ { http_response_code => 402,
      http_status_line   => '402 OK OK OK',
      http_body =>
        '{ "status": "error", "response_code": 1101, "response_message": "Invalid Credentials" }'
    },
    { http_response_code => 402,
      http_status_line   => '402 OK OK OK',
      status             => "error",
      response_code      => 1101,
      response_message   => "Invalid Credentials",
      other              => {}
    },
  ],
  [ { http_response_code => 200,
      http_status_line   => '402 OK OK OK',
      http_body =>
        '{ "status": "success", "response_code": 2201, "response_message": "OK" }',
      field_1 => 'one',
      field_2 => 'two'
    },
    { http_response_code => 200,
      http_status_line   => '402 OK OK OK',
      status             => "success",
      response_code      => 2201,
      response_message   => "OK",
      other              => {
        field_1 => 'one',
        field_2 => 'two'
      }
    },
  ],
  [ { http_response_code => 500,
      http_status_line   => '500 no way',
      http_body          => '500 no way',
      field_1            => 'one',
      field_2            => 'two'
    },
    { http_response_code => 500,
      http_status_line   => '500 no way',
      status             => "error",
      response_code      => -1,
      response_message   => "500 no way",
      other              => {
        field_1 => 'one',
        field_2 => 'two'
      }
    },
  ],
);

for my $tc (@test_cases) {
  my ($args, $expected) = @$tc;

  my $result;
  lives_ok sub { $result = $n->parse_response(%$args) },
    'Parsed response lived';
  cmp_deeply($result, $expected, '... data is as expected');
}

done_testing();

