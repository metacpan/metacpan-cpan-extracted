#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious;

use Test::More;
use Test::Mojo;

my $script = 't/script/env.psgi';

subtest 'trivial mount' => sub {
  my $app = Mojolicious->new;
  $app->plugin(MountPSGI => { '/' => $script });
  my $t = Test::Mojo->new($app);

  $t->post_ok('/' => {'Content-Type' => 'text/plain'} => 'hello')
    ->status_is(200)
    ->json_hasnt('/HTTP_CONTENT_LENGTH')
    ->json_is('/CONTENT_LENGTH' => 5)
    ->json_hasnt('/HTTP_CONTENT_TYPE')
    ->json_is('/CONTENT_TYPE' => 'text/plain');
};

subtest 'nontrivial mount without rewrite' => sub {
  my $app = Mojolicious->new;
  $app->plugin(MountPSGI => { '/mount' => $script });
  my $t = Test::Mojo->new($app);

  $t->get_ok('/mount')
    ->status_is(200)
    ->json_is('/PATH_INFO' => '/mount')
    ->json_is('/SCRIPT_NAME' => '');
};

subtest 'nontrivial mount with rewrite' => sub {
  my $app = Mojolicious->new;
  $app->plugin(MountPSGI => { '/mount' => $script, rewrite => 1 });
  my $t = Test::Mojo->new($app);

  $t->get_ok('/mount')
    ->status_is(200)
    ->json_is('/PATH_INFO' => '/')
    ->json_is('/SCRIPT_NAME' => '/mount');
};

done_testing;

