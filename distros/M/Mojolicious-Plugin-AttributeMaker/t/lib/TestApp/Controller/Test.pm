package TestApp::Controller::Test;
use Mojo::Base 'Mojolicious::Controller';
use Test::More;
use Test::Mojo;

sub welcome : Local {
    my $self = shift;
    $self->render( text => 'Local' );
}

sub welcome1 : Path('test1') {
    my $self = shift;
    $self->render( text => 'Path' );
}

sub welcome2 : Path('/test2') {
    my $self = shift;
    $self->render( text => 'Path' );
}

sub welcome3 : Global {
    my $self = shift;
    $self->render( text => 'Global' );
}

sub welcome4 : Global('test4') {
    my $self = shift;
    $self->render( text => 'Global' );
}

sub welcome5 : Global('/test5') {
    my $self = shift;
    $self->render( text => 'Global' );
}
1;
