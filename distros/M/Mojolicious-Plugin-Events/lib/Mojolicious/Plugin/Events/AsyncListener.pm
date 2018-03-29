package Mojolicious::Plugin::Events::AsyncListener;
use Mojo::Base 'Mojolicious::Plugin::Events::Listener';

use Mojo::IOLoop;

=head2 handle

Handle event

=cut

sub handle {
    return shift->async(@_);
}

=head2 async

Handle the event async

=cut

sub async {
    my ($self, $data) = @_;
    
    Mojo::IOLoop->timer(0 => sub {
        return $self->handler($data);
    });

    # When running from a command, ioloop is not running
    # so we need to start it
    Mojo::IOLoop->start if (!Mojo::IOLoop->is_running);
}

1;
