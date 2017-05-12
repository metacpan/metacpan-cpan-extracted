package PliftApp;

use Mojo::Base 'Mojolicious';
use lib "$ENV{HOME}/workspace/Plift/lib";

sub startup {
    my $self = shift;

    $self->plugin('Plift');
    $self->renderer->default_handler('plift');

    my $r = $self->routes;

    $r->get('/index' => { template => 'index' });

    $r->get('/layout' => {
        template => 'index',
        layout => 'layout',
    });

    $r->get('/meta' => {
        template => 'meta',
        title => 'Controller Title'
    });

    $r->get('/inline' => { inline => q{
        <div id="inline-content">
            <h1 data-render="username+">Hello, </h1>
        </div>
    }});

    $r->get('/snippet' => { inline => '<div data-plift="foo"></div>' });

    $r->get('/tag/:tag' => sub {
        my $c = shift;
        $c->render( template => 'tag/'.$c->stash->{tag});
    });

    $r->get('/custom_response' => { inline => '<div data-plift="custom_response"></div>' });
}


BEGIN {

    package PliftApp::Snippet::Foo;
    use Moo;

    sub process {
        my ($self, $element, $c) = @_;
        $element->text(ref $c->app);
    }

    package PliftApp::Snippet::CustomResponse;
    use Moo;

    sub process {
        my ($self, $element, $c) = @_;

        $c->res->code(402);
        $c->res->body('CustomResponse');
    }

}



1;
