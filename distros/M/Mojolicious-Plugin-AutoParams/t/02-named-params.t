use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'auto_params', { named => 1 };

get '/one/:first' => sub {
    my ($c,%args) = @_;
    $c->render(text => $args{first} || 'fail');
};

get '/two/:first/:second' => sub {
    my ($c,%args) = @_;
    $c->render(text => "$args{first},$args{second}");
};

my $t = Test::Mojo->new;

$t->get_ok('/one/two')->status_is(200)->content_is('two');

$t->get_ok('/two/blue/cheese')->status_is(200)->content_is('blue,cheese');

done_testing();

__DATA__
@@ exception.html.ep
<%= $exception %>

