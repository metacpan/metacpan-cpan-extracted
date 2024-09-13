package Mojolicious::Plugin::Debugbar;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Debugbar;

our $VERSION = '0.1.2';

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

        return unless $format eq 'html';

        # if there is a </body> tag, inject the debugbar
        if ($$output =~ m/<\/body>/) {
            # Render the debugbar html
            my $html = $debugbar->render;

            # Append text before the closing </body> tag
            $$output =~ s!(</body>)!$html$1!;
        } else {
            # Append text at the end of the output
            $$output .= $debugbar->inject;
        }
    });
}

1;
