use Mojo::Base -strict;
use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'JSONP';

get '/jsonp' => sub {
  my $self = shift;
  $self->render_jsonp($self->param('callback') => {qw/ one two /});
};

get '/json' => sub { shift->render_jsonp({qw/ one two /}) };

my $t = Test::Mojo->new;

$t->get_ok('/jsonp?callback=hello')->status_is(200)
  ->content_is('hello({"one":"two"})');

$t->get_ok('/json')->status_is(200)->content_is('{"one":"two"}');

done_testing;
