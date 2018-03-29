package Mojolicious::Plugin::Events::Dispatcher;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::Server;

has 'app' => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') };

=head2 new

Initialize dispatched and startup listeners

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    $self->app->listeners->startup($self);

    return $self;
}

=head2 dispatch

Dispatch event

=cut

sub dispatch {
    return shift->emit(@_);
}

1;
