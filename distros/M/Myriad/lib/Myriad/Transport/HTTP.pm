package Myriad::Transport::HTTP;

use Myriad::Class extends => 'IO::Async::Notifier';

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Net::Async::HTTP;
use Net::Async::HTTP::Server;

has $client;
has $server;
has $listener;
has $requests;
has $ryu;

method configure (%args) {

}

method on_request ($srv, $req) {
    $requests->emit($req);
}

method listen_port () { 80 }

method _add_to_loop ($) {
    $self->next::method;

    $self->add_child(
        $ryu = Ryu::Async->new
    );
    $requests = $ryu->source;

    $self->add_child(
        $client = Net::Async::HTTP->new(
        )
    );
    $self->add_child(
        $server = Net::Async::HTTP::Server->new(
            on_request => $self->curry::weak::on_request,
        )
    );
    $listener = $server->listen(
        addr => {
            family => 'inet',
            socktype => 'stream',
            port => $self->listen_port,
        }
    );
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

