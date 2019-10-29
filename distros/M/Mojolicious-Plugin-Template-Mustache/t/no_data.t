use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Template::Mustache';

get '/data' => sub {
    my $c = shift;
    $c->render(
        handler => 'mustache',
        message => 'Mustache',
    );
};

Test::Mojo->new->get_ok('/data')->status_is(200)->content_is('');

done_testing();