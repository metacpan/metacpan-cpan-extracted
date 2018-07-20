#! perl -w

use Test::Most;

use Mojolicious::Lite;
use Test::Mojo;

use Data::Dumper;

plugin 'JSONAPI';

get '/' => sub {
    my $c = shift;
    return $c->render_error(400);
};

get '/custom-error' => sub {
    my $c = shift;
    return $c->render_error(400, [{ title => 'custom' }]);
};

get '/with-data-and-meta' => sub {
    my $c = shift;
    return $c->render_error(400, [{ title => 'custom' }], { data => { my => 'data' } }, { my => 'meta' });
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(400)->json_has('/errors/0/title')->json_has('/errors/0/status');

$t->get_ok('/custom-error')->status_is(400)->json_has('/errors/0/title')->json_is('/errors/0/title', 'custom')
    ->json_hasnt('/errors/0/status');

$t->get_ok('/with-data-and-meta')->status_is(400)->json_has('/errors/0/title')->json_is('/errors/0/title', 'custom')
    ->json_hasnt('/errors/0/status')->json_is('/data/my', 'data')->json_is('/meta/my', 'meta');

done_testing;
