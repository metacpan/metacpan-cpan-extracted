package Local::Controller::Extended;
use Mojo::Base 'Mojolicious::Plugin::DBIC::Controller::DBIC';

sub list {
    my ( $c ) = @_;
    $c->SUPER::list() || return;
    $c->render( extended => 'Extended' );
}

sub get {
    my ( $c ) = @_;
    $c->SUPER::get() || return;
    $c->render( extended => 'Extended' );
}

1;
