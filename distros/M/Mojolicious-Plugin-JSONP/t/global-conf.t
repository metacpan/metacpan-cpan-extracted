use Mojo::Base -strict;
use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin JSONP => callback => 'callback';

get '/' => sub { shift->render_jsonp({qw/ one two /}) };

my $t = Test::Mojo->new;

$t->get_ok('/?callback=hello')->status_is(200)
  ->content_is('hello({"one":"two"})');

$t->get_ok('/')->status_is(200)->content_is('{"one":"two"}');

done_testing;
