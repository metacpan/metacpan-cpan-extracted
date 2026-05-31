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
   my $response = $tus->HTTP_request(
      method => 'POST',
      headers => {
         'Tus-Resumable' => '1.0.0',
         'Upload-Length' => 10,
      },
   );
   my $to = tus_response($response, 'first, create');
   $to->no_exception
      ->status_is(201)
      ->body_is('');

   my $id = $response->id;
   $response = $tus->HTTP_request(
      method => 'PATCH',
      headers => {
         'Tus-Resumable' => '1.0.0',
         'Upload-Offset' => 0
      },
      id => $id,
      body => 'hello',
   );
   $to = tus_response($response, 'first, first chunk');
   $to->no_exception
      ->status_is(204)
      ->body_is('')
      ->header_is('Upload-Offset' => 5);

   # this request is "wrong" and we expect to receive an error back
   $response = $tus->HTTP_request(
      method => 'PATCH',
      headers => {
         'Tus-Resumable' => '1.0.0',
         'Upload-Offset' => 3,
      },
      id => $id,
      body => 'world'
   );
   $to = tus_response($response, 'first, misaligned chunk upload');
   $to->status_is(409)
      ->exception_like(qr{(?mxs:\A offset \s+ mismatch \z)});

   $response = $tus->HTTP_request(
      method => 'HEAD',
      headers => { 'Tus-Resumable' => '1.0.0' },
      id => $id,
   );
   $to = tus_response($response, 'first, HEAD request for info');
   $to->no_exception
      ->status_is(204)
      ->body_is('')
      ->header_is('Upload-Offset' => 5)
      ->header_is('Upload-Length' => 10);
   ok !$model->is_complete($id), 'upload still not complete';

   $response = $tus->HTTP_request(
      method => 'PATCH',
      headers => {
         'Tus-Resumable' => '1.0.0',
         'Upload-Offset' => 5,
      },
      id => $id,
      body => \'world',
   );
   $to = tus_response($response, 'first, second and final chunk');
   $to->no_exception
      ->status_is(204)
      ->body_is('')
      ->header_is('Upload-Offset' => 10);
   ok $model->is_complete($id), 'upload complete now';

   $response = $tus->HTTP_request(
      method => 'HEAD',
      headers => { 'Tus-Resumable' => '1.0.0' },
      id => $id,
   );
   $to = tus_response($response, 'first, HEAD request for info');
   $to->no_exception
      ->status_is(204)
      ->body_is('')
      ->header_is('Upload-Offset' => 10)
      ->header_is('Upload-Length' => 10);
   ok $model->is_complete($id), 'upload complete now';

   $response = $tus->HTTP_request(
      method => 'PATCH',
      headers => {
         'Tus-Resumable' => '1.0.0',
         'Upload-Offset' => 10,
      },
      id => $id,
   );
   $to = tus_response($response, 'first, no-chunk after completion');
   $to->no_exception
      ->status_is(204)
      ->body_is('')
      ->header_is('Upload-Offset' => 10);
   ok $model->is_complete($id), 'upload complete now';

   # try to push more data after completion
   $response = $tus->HTTP_request(
      method => 'PATCH',
      headers => {
         'Tus-Resumable' => '1.0.0',
         'Upload-Offset' => 10,
      },
      id => $id,
      body => 'foo',
   );
   $to = tus_response($response, 'first, chunk over limit');
   $to->status_is(400)
      ->exception_like(qr{(?mxs:\A file \s+ is \s+ complete)});

   my $path = $model->resolve_path($id);
   ok $path->is_dir, 'path is a directory';
   is $path->child('data')->slurp_raw, 'helloworld', 'file contents';

   $response = $tus->HTTP_request(
      method => 'DELETE',
      headers => { 'Tus-Resumable' => '1.0.0', },
      id => $id,
   );
   $to = tus_response($response, 'first, deletion');
   $to->no_exception
      ->status_is(204)
      ->body_is('');
   ok !$path->exists, 'directory has been eliminated';
   
   # on second attempt to delete we get a 404 because there's no directory
   $response = $tus->HTTP_request(
      method => 'DELETE',
      headers => { 'Tus-Resumable' => '1.0.0', },
      id => $id,
      body => \'',
   );
   $to = tus_response($response, 'first, second deletion');
   $to->status_is(404);
}

done_testing();
