use Mojolicious::Lite;

get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello, World! (HTTP/2)');
};

app->start;