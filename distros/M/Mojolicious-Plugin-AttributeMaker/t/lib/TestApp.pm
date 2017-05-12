package TestApp;
use Mojo::Base 'Mojolicious';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

sub startup {
    my $self = shift;

    $self->plugin(
        'AttributeMaker',
        {
            controllers => 'TestApp::Controller'
        }
    );
}
1;