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

    $app->hook(after_render => sub {
        my ($c, $output, $format) = @_;

        if (!$c->stash('mojo.static') && !$c->res->is_redirect && $$output =~ m/<\/body>/) {
            # Render the debugbar html
            my $html = $debugbar->render;

            # Inject the debugbar html
            $$output =~ s/<\/body>/$html\n<\/body>/ig;
        }
    });
}

1;
