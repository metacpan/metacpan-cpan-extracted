#!perl

use Test::More tests => 9;
use Mojolicious::Lite;
use Test::Mojo;

get '/hello' => { layout => 'default' } => sub { shift->render( text => 'hello' ) };

plugin 'toto' => nav => [qw/this that theother/],
  sidebar     => {
    this     => ['x/y', 'z/bar', qw/x z/],
    that     => ['z/p', qw/five/],
    theother => [ 'five/six', 'seven/eight', 'seven' ],
  },
  tabs => {
    x   => [qw/a b c/],
    z   => [qw/d e f/],
    five => [qw/f g h/],
    seven  => [qw/i j k/],
  },
;

my $t = Test::Mojo->new();

$t->get_ok('/hello')->status_is(200)->content_is('hello');

$t->get_ok('/')->status_is(302);

$t->get_ok('/this')->status_is(302);

$t->get_ok('/five/f/1')->status_is(200);

1;


