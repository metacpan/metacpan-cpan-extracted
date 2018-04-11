#! perl -w

use Test::Most;

use Mojolicious::Lite;
use Test::Mojo;

use Data::Dumper;

plugin 'JSONAPI', { data_dir => 't/share' };

get '/' => sub {
    my $c = shift;

    return $c->render_error(400);
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(400)
    ->json_has('/errors/0/title')
    ->json_has('/errors/0/status');

done_testing;
