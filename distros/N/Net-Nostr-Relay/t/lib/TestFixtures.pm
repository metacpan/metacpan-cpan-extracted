package TestFixtures;

use strictures 2;
use Exporter 'import';

our @EXPORT_OK = qw(%FIATJAF_EVENT make_event make_key_from_hex relay_peer free_port signed_event);

# A real-world note from fiatjaf
our %FIATJAF_EVENT = (
    id => 'deb8b23368b6c658c36cf16396927a045dee0b7707b4133d714fb67264cc10cc',
    kind => 1,
    pubkey => '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d',
    created_at => 1673361254,
    content => 'hello',
    tags => [],
    sig => 'f5e5e8a477c6749ef8562c23cdfec7a6917c975ec55075489cb3319b8a2ccb78317335a6850fb3a3714777b1c22611419d6c81ce4b0b88db86e2d1662bb17540'
);

sub make_event {
    require Net::Nostr::Event;
    my %defaults = %FIATJAF_EVENT;
    delete @defaults{qw(id sig)};
    return Net::Nostr::Event->new(%defaults, @_);
}

sub make_key_from_hex {
    my ($hex_privkey) = @_;
    require Crypt::PK::ECC;
    require Net::Nostr::Key;
    my $pk = Crypt::PK::ECC->new;
    $pk->import_key_raw(pack('H*', $hex_privkey), 'secp256k1');
    my $key = bless {}, 'Net::Nostr::Key';
    $key->{_cryptpkecc} = $pk;
    return $key;
}

sub signed_event {
    my ($key, %args) = @_;
    my $event = make_event(pubkey => $key->pubkey_hex, created_at => time, %args);
    $key->sign_event($event);
    return $event;
}

sub free_port {
    require IO::Socket::INET;
    my $socket = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
        Listen => 1, Proto => 'tcp') or die "cannot allocate port: $!";
    my $port = $socket->sockport;
    close $socket;
    return $port;
}

sub relay_peer {
    my ($url) = @_;
    require AnyEvent;
    require AnyEvent::WebSocket::Client;
    require JSON;
    my $self = bless { url => $url, messages => [] }, 'TestFixtures::RelayPeer';
    my $cv = AnyEvent->condvar;
    my $client = AnyEvent::WebSocket::Client->new;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak('connection timed out') });
    $client->connect($url)->cb(sub {
        my $connection = eval { shift->recv };
        return $cv->croak($@) if $@;
        $self->{connection} = $connection;
        $connection->on(each_message => sub {
            push @{$self->{messages}}, JSON::decode_json($_[1]->body);
            $self->{wake}->() if $self->{wake};
        });
        $cv->send;
    });
    $cv->recv;
    $self->{challenge} = $self->wait_for('AUTH')->[1];
    return $self;
}

package TestFixtures::RelayPeer;
use strictures 2;

sub wait_for {
    my ($self, $type, $id) = @_;
    my $cv = AnyEvent->condvar;
    my $check = sub {
        for my $i (0 .. $#{$self->{messages}}) {
            my $m = $self->{messages}[$i];
            if ($m->[0] eq $type && (!defined($id) || $m->[1] eq $id)) {
                $cv->send(splice @{$self->{messages}}, $i, 1);
                return;
            }
        }
    };
    local $self->{wake} = $check;
    my $timer = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timed out waiting for $type") });
    $check->();
    return $cv->recv;
}

sub request {
    my ($self, $wire, $type, $id) = @_;
    $self->{connection}->send(JSON::encode_json($wire));
    return $self->wait_for($type, $id);
}

sub authenticate {
    my ($self, $key) = @_;
    my $event = TestFixtures::signed_event($key, kind => 22242, content => '',
        tags => [['relay', $self->{url}], ['challenge', $self->{challenge}]]);
    return $self->request(['AUTH', $event->to_hash], 'OK', $event->id);
}

sub take_events {
    my ($self) = @_;
    # COUNT is an ordered round-trip barrier for earlier server writes.
    $self->request(['COUNT', 'barrier', { kinds => [65535] }], 'COUNT', 'barrier');
    my @events = grep { $_->[0] eq 'EVENT' } @{$self->{messages}};
    $self->{messages} = [];
    return \@events;
}

sub close { $_[0]->{connection}->close }

1;
