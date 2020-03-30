use Mojo::Base '-strict';
use Mojolicious::Lite;

app->log->level('error');

get '/' => sub {
    my $self = shift;

    return $self->render(text => "It works");
};

any '/:name' => sub {
    my $self = shift;
    my $name = $self->param('name');
    my $body = $self->req->json;
     
    return $self->render(json => {name => $name, body => $body});
};

app->start;

