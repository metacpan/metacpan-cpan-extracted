package MyApp;
use Mojo::Base 'Mojolicious';
use FindBin;

use lib "$FindBin::Bin/../lib";

sub startup {
    my $self = shift;

    $self->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::I18N' => {
                default   => 'en',
                share_dir => "$FindBin::Bin/share",
            }},
        ],
    });

    # Test routes that use l() helper
    my $r = $self->routes;

    $r->get('/translate')->to(cb => sub {
        my $c = shift;
        $c->render(text => $c->l('Welcome'));
    });

    $r->get('/raw')->to(cb => sub {
        my $c = shift;
        $c->render(text => $c->l('Unknown text'));
    });
}

1;
