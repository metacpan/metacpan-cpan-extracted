use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'auto_params';

get '/basic' => sub {
    shift->render(text => 'basic');
};

get '/one/:first' => sub {
    my ($c,$first) = @_;
    $c->render(text => $first || 'fail');
};

get '/two/:first/:second' => sub {
    my ($c,$first,$second) = @_;
    $c->render(text => "$first,$second");
};

my $t = Test::Mojo->new;

$t->get_ok('/basic')->status_is(200)->content_is('basic');

$t->get_ok('/one/two')->status_is(200)->content_is('two');

$t->get_ok('/two/blue/cheese')->status_is(200)->content_is('blue,cheese');

done_testing();

__DATA__
@@ exception.html.ep
<%= $exception %>

