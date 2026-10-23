use Mojolicious::Lite -signatures;
use Mojo::File qw(curfile);

plugin WebComponent => {};

my $here = curfile->dirname;
app->static->paths([$here->child('public')->to_string]);
app->renderer->paths([$here->child('templates')->to_string]);

get '/page' => sub($c) {
    $c->render(inline => '<!DOCTYPE html><html><head><%= component "my-component" %><%= component "echo-box" %><%= component "tick-box" %><%= component "inline-box", {template => undef} %></head><body><my-component></my-component><echo-box></echo-box><tick-box></tick-box><inline-box></inline-box></body></html>');
};

app->start;
