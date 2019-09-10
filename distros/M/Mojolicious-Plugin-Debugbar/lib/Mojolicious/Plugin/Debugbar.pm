package Mojolicious::Plugin::Debugbar;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Debugbar;

our $VERSION = '0.0.2';

=head2 register

=cut

sub register {
    my ($self, $app, $config) = @_;

    my $debugbar = Mojo::Debugbar->new(app => $app, config => $config);

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;

        # Start recording
        $debugbar->start;

        $next->();

        # Stop recording
        $debugbar->stop;
    });

    $app->hook(after_dispatch => sub {
        my $c = shift;
        
        if (!$c->stash('mojo.static') && !$c->res->is_redirect && $c->res->body =~ m/<\/body>/) {
            # Render the debugbar html
            my $html = $debugbar->render;

            my $body = $c->res->body;

            # Inject the debugbar html
            $body =~ s/<\/body>/$html\n<\/body>/ig;

            # Set the new body html
            $c->res->body($body);
        }
    });
}

1;
