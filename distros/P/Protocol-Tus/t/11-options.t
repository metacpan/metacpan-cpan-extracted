#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental qw< signatures >;
use Test::More 'no_plan';  # substitute with previous line when done
use Test::Exception;

use Protocol::Tus;

use Path::Tiny;
use lib path(__FILE__)->parent;
use Test::TusResponse;

my $root = path(__FILE__)->parent->tempdir;
END { $root->remove_tree({ safe => 0 }); }

my $tus;
lives_ok {
   $tus = Protocol::Tus->new(
      model => {
         class => 'Protocol::Tus::LocalDir',
         args  => { root => $root },
      }
   );
} 'constructor for Protocol::Tus';
isa_ok $tus, 'Protocol::Tus';

# indirect calls via HTTP_request
for my $spec (
   [OPTIONS => {}, 'normal'],
   [FOO => { 'X-HTTP-Method-Override' => 'OPTIONS' }, 'method override'],
) {
   my ($method, $headers, $msg) = $spec->@*;
   my $response;
   lives_ok {
      $response = $tus->HTTP_request(
         method => $method,
         headers => $headers,
      );
   } 'HTTP_request';
   check_response($response, $msg);
}

{
   my $response;
   lives_ok { $response = $tus->HTTP_OPTIONS } 'HTTP_OPTIONS';
   check_response($response, 'direct call');
}

sub check_response ($response, $msg) {
   isa_ok $response, 'Protocol::Tus::Response';

   my $to = tus_response($response, $msg);
   isa_ok $to, 'Test::TusResponse'
     or BAIL_OUT 'something wrong with the test library Test::TusResponse';

   $to->no_exception
      ->status_is(204)
      ->body_is('')
      ->header_is('Tus-Version' => '1.0.0');
}

done_testing();

