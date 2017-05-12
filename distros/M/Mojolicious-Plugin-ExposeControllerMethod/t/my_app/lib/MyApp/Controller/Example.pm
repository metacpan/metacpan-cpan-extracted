package MyApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

sub name           { return 'Mark Fowler' }
sub any_other_name { return 'Still smells sweet' }
sub repeat         { my $self = shift; return shift() x shift() }

my $counter = {};

sub controller_method_name {
    my $self = shift;
    my $what = shift;

    ## no critic(ValuesAndExpressions::ProhibitAccessOfPrivateData)
    # keep track of how many times we're called for each thing
    $counter->{$what}++;
    ## use critic

    return $what if $what =~ /\A(name|repeat)\z/;
    return 'any_other_name' if $what eq 'rose';
    return;
}

sub counter {
    my $self = shift;
    $self->render( json => $counter );
}

# This action will render a template
sub welcome {
    my $self = shift;

    # Render template "example/welcome.html.ep" with message
    $self->render(
        msg => 'Welcome to the Mojolicious real-time web framework!' );
}

1;
