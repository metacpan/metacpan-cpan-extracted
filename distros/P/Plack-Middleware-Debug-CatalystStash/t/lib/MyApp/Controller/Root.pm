package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config(namespace => '');

sub default: Private {
    my ( $self, $c ) = @_;

    $c->stash(
        ar  => [
            "bar",
            1,
            2,
            3,
            {
                key => 'value',
            },
            sub {
                my ( $one, $two ) = @_;

                return $one + $two;
            },
        ],
    );
    $c->res->content_type('text/html');
    #plack::middleware::debug want's a <body> element, so we'll do this horrible thing
    $c->res->body('<body><p>default action</p></body>');
}

__PACKAGE__->meta->make_immutable;
