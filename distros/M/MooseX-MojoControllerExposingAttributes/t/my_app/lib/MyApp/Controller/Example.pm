package MyApp::Controller::Example;
use MooseX::MojoControllerExposingAttributes;

has name => (
    is      => 'ro',
    lazy    => 1,
    default => 'Mark Fowler',
    traits  => ['ExposeMojo'],
);

has any_other_name => (
    is                => 'ro',
    lazy              => 1,
    default           => 'Still smells sweet',
    traits            => ['ExposeMojo'],
    expose_to_mojo_as => 'rose',
);

has custom => (
    is      => 'ro',
    lazy    => 1,
    default => 'custom reader works',
    traits  => ['ExposeMojo'],
    reader  => 'get_custom',
);

# This action will render a template
sub welcome {
    my $self = shift;

    # Render template "example/welcome.html.ep" with message
    $self->render(
        msg => 'Welcome to the Mojolicious real-time web framework!',
    );
}

1;
