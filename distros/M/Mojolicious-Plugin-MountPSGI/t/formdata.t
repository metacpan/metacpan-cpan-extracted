#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious;

use Test::More;
use Test::Mojo;

my $script = 't/script/formdata.psgi';

subtest 'single part' => sub {
  my $app = Mojolicious->new;
  $app->plugin(MountPSGI => { '/' => $script });
  my $t = Test::Mojo->new($app);

  $t->post_ok('/' => form => {a => 'b'})
    ->status_is(200)
    ->json_is({a => 'b'});
};

subtest 'multipart' => sub {
  my $app = Mojolicious->new;
  $app->plugin(MountPSGI => { '/' => $script });
  my $t = Test::Mojo->new($app);

  $t->post_ok('/' => {'Content-Type' => 'multipart/form-data'}, form => {a => 'b'})
    ->status_is(200)
    ->json_is({a => 'b'});
};

subtest 'multipart with file' => sub {
  my $app = Mojolicious->new;
  $app->plugin(MountPSGI => { '/' => $script });
  my $t = Test::Mojo->new($app);

  my $form = {
    a => 'b',
    f => {
      content => 'foo',
      filename => 'foo.txt',
      'Content-Type' => 'text/plain',
    },
  };
  $t->post_ok('/' => form => $form)
    ->status_is(200)
    ->json_is({a => 'b', _upload => { f => [3, 'foo.txt', 'foo'] }});
};

done_testing;


