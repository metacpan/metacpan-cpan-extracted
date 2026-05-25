#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental qw< signatures >;
use Test::More 'no_plan';  # substitute with previous line when done
use Test::Exception;

use Protocol::Tus;
use Protocol::Tus::LocalDir;

use Path::Tiny;
use lib path(__FILE__)->parent;
use Test::TusResponse;

my $root = path(__FILE__)->parent->tempdir(CLEANUP => 1);

my $model;
lives_ok { $model = Protocol::Tus::LocalDir->new(root => $root) }
   'constructor for Protocol::Tus::LocalDir';
isa_ok $model, 'Protocol::Tus::AbstractModel', 'Protocol::Tus::LocalDir';

my $tus;
lives_ok { $tus = Protocol::Tus->new(model => $model); }
   'constructor for Protocol::Tus';
isa_ok $tus, 'Protocol::Tus';

{
   my $response;
   lives_ok {
      $response = $tus->HTTP_POST(
         {
            'Tus-Resumable' => '1.0.0',
            'Upload-Length' => 0,
         },
         '',
      )
   } 'HTTP_POST';
   check_response($response, 'direct call');
}

{
   my $response;
   lives_ok {
      $response = $tus->HTTP_POST(
         {
            'Tus-Resumable' => '1.0.0',
            'Upload-Length' => 5,
         },
         'hello',
      )
   } 'HTTP_POST';
   check_response($response, 'direct call');
}

# indirect calls via HTTP_request
for my $spec (
   [POST => {}, '', 'normal'],
   [FOO => { 'X-HTTP-Method-Override' => 'POST' }, '', 'method override'],
) {
   my ($method, $headers, $body, $msg) = $spec->@*;
   my %headers = (
      'Tus-Resumable' => '1.0.0',
      'Upload-Length' => 0,
      $headers->%*,
   );

   my $response;
   lives_ok {
      $response = $tus->HTTP_request($method, \%headers, undef, $body);
   } 'HTTP_request';
   check_response($response, $msg);
}

{
   my $response;
   lives_ok {
      $response = $tus->HTTP_POST(
         {
            'Tus-Resumable' => '1.0.0',
            'Upload-Length' => 10,
         },
         'hello',
      )
   } 'HTTP_POST';
   check_response($response, 'direct call', 0);

   my $id = $response->id;
   is $model->get_offset($id), 5, 'current offset';
}

sub check_response ($response, $msg, $exp_complete = 1) {
   isa_ok $response, 'Protocol::Tus::Response';

   my $to = tus_response($response, $msg);
   isa_ok $to, 'Test::TusResponse'
     or BAIL_OUT 'something wrong with the test library Test::TusResponse';

   $to->no_exception
      ->status_is(201)
      ->body_is('');

   ok length($response->id // ''), 'identifier present';

   my $got_complete = $model->is_complete($response->id);
   if ($exp_complete) {
      ok $got_complete, 'upload marked as complete';
   }
   else {
      ok !$got_complete, 'upload still ongoing';
   }
   
}

done_testing();
