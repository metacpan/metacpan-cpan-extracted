#!perl

use strict;
use warnings;

# Cribbed from mojo's t/mojolicious/lite_app.t:
# Disable epoll, kqueue and IPv6
BEGIN { $ENV{MOJO_POLL} = $ENV{MOJO_NO_IPV6} = 1 }

use Mojo::IOLoop;
use Test::More;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 15;

use Mojolicious 0.999930;
use Mojolicious::Lite;
use Test::Mojo;

app->log->level('fatal');

plugin 'write_excel';

get '/demo.xls' => sub {
  shift->render(
    handler => 'xls',
    heading => [qw(Firstname Middle LastName)],
    result =>
      [[qw(Zak B Elep)], [qw(Joel T Tanangonan)], [qw(Jerome S Gotangco)],],
  );
};

get '/demo_without_heading.xls' => sub {
  shift->render(
    handler => 'xls',
    result  => [[qw(foo bar baz)], [qw(lol wut bbq)], [qw(kick ass module)],],
  );
};

get '/demo_with_column_width.xls' => sub {
  shift->render(
    handler  => 'xls',
    result   => [],
    settings => {column_width => {'A:A' => 10, 'B:B' => 25, 'C:D' => 40}},
  );
};

get '/demo_with_broken_column_width_1.xls' => sub {
  shift->render(
    handler  => 'xls',
    result   => [],
    settings => {column_width => undef},
  );
};

get '/demo_with_app_helper.xls' => sub {
  shift->render_xls(
    result => [[qw(foo bar baz)], [qw(lol wut bbq)], [qw(kick ass module)],],
  );
};

# Test
my $t = Test::Mojo->new;

$t->get_ok('/demo.xls')->status_is(200)
  ->content_type_is('application/vnd.ms-excel');

$t->get_ok('/demo_without_heading.xls')->status_is(200)
  ->content_type_is('application/vnd.ms-excel');

$t->get_ok('/demo_with_column_width.xls')->status_is(200)
  ->content_type_is('application/vnd.ms-excel');

$t->get_ok('/demo_with_broken_column_width_1.xls')->status_is(500)
  ->content_type_is('text/html;charset=UTF-8');

$t->get_ok('/demo_with_app_helper.xls')->status_is(200)
  ->content_type_is('application/vnd.ms-excel');
