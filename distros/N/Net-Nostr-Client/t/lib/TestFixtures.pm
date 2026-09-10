package TestFixtures;

use strictures 2;
use Exporter 'import';
use Net::Nostr::Client;
use Net::Nostr::Key;
use AnyEvent::WebSocket::Message;

our @EXPORT_OK = qw(make_signed_event client_connection);

my $key;

sub make_signed_event {
    $key ||= Net::Nostr::Key->new;
    return $key->create_event(
        kind => 1, content => 'test', created_at => 1000, tags => [], @_,
    );
}

sub client_connection {
    my $client = Net::Nostr::Client->new;
    my $conn = TestFixtures::Connection->new;
    $client->_conn($conn);
    $client->_setup_handlers;
    return ($client, $conn);
}

# Deliver wire messages through the real client receive handler without a socket.
package TestFixtures::Connection;

use Class::Tiny qw(handlers);
use JSON ();

sub new { bless { handlers => {} }, shift }

sub on {
    my ($self, $type, $cb) = @_;
    $self->handlers->{$type} = $cb;
}

sub receive {
    my ($self, $body) = @_;
    $self->handlers->{each_message}->(
        $self, AnyEvent::WebSocket::Message->new(body => $body),
    );
}

sub send {
    my ($self, $wire) = @_;
    push @{$self->{sent}}, JSON::decode_json($wire);
}

1;
