use utf8;

package Net::EGTS::Simple;
use Mouse;

use Carp;
use IO::Socket::INET;

use Net::EGTS::Util;
use Net::EGTS::Types;
use Net::EGTS::Codes;

use Net::EGTS::Packet;
use Net::EGTS::Record;
use Net::EGTS::SubRecord;

use Net::EGTS::Packet::Appdata;
use Net::EGTS::SubRecord::Auth::DispatcherIdentity;
use Net::EGTS::SubRecord::Teledata::PosData;

=head1 NAME

Net::EGTS::Simple - simple blocking socket transport

=cut

# Timeout, sec. (0 .. 255)
use constant EGTS_SL_NOT_AUTH_TO        => 6;

# Response timeout
use constant EGTS_TL_RESPONSE_TO        => 5;
# Resend attempts if timeout EGTS_TL_RESPONSE_TO
use constant EGTS_TL_RESEND_ATTEMPTS    => 3;
# Connection timeout
use constant EGTS_TL_RECONNECT_TO       => 30;

has host        => is => 'ro', isa => 'Str', required => 1;
has port        => is => 'ro', isa => 'Int', required => 1;

has timeout     => is => 'ro', isa => 'Int', default => EGTS_TL_RECONNECT_TO;
has attempts    => is => 'ro', isa => 'Int', default => EGTS_TL_RESEND_ATTEMPTS;
has rtimeout    => is => 'ro', isa => 'Int', default => EGTS_TL_RESPONSE_TO;

has did         => is => 'ro', isa => 'Int', required => 1;
has type        => is => 'ro', isa => 'Int', default => 0;
has description => is => 'ro', isa => 'Maybe[Str]';

has socket      =>
    is          => 'ro',
    isa         => 'Object',
    lazy        => 1,
    clearer     => 'socket_drop',
    builder     => sub {
        my ($self) = @_;
        my $socket = IO::Socket::INET->new(
            PeerAddr    => $self->host,
            PeerPort    => $self->port,
            Proto       => 'tcp',
            Timeout     => $self->timeout,
        );
        die "Open socket error: $!\n" unless $socket;
        return $socket;
    }
;

=head2 reset

Reset internal counters for new connection

=cut

sub reset {
    $Net::EGTS::Packet::PID = 0;
    $Net::EGTS::Record::RN  = 0;
}

=head2 connect

=cut

sub connect {
    my ($self) = @_;
    $self->disconnect if $self->socket;
    $self->reset;
    return $self;
}

=head2 disconnect

=cut

sub disconnect {
    my ($self) = @_;
    $self->socket->shutdown(2);
    $self->socket_drop;
    $self->reset;
    return $self;
}

# Get packet response
sub _response {
    my ($self, $packet) = @_;

    my $response;
    my $start = time;
    while (1) {
        my $in = '';
        my $res = sysread $self->socket, $in, 65536;
        return 'Recv error' unless defined $res;

        my ($p) = Net::EGTS::Packet->stream( \$in );
        if( $p ) {
            next unless $p->PT      eq EGTS_PT_RESPONSE;
            next unless $p->RPID    eq $packet->PID;

            $response = $p;
            last;
        }

        last if time > $start + $self->rtimeout;
    }
    return 'Response timeout' unless $response;

    my $record = $response->records->[0];
    return 'No records' unless $record;

    my $subrecord = $record->subrecords->[0];
    return 'No subrecords' unless $subrecord;
    return "Error on packet @{[ $subrecord->CRN ]}"
        unless $subrecord->RST eq EGTS_PC_OK;

    return $self;
}

=head2 auth

Athorization

=cut

sub auth {
    my ($self) = @_;
    use bytes;

    my $result;
    for(my $i = $self->attempts; $i > 0; $i-- ) {
        my $auth = Net::EGTS::Packet::Appdata->new(
            PRIORITY        => 0b11,
            SDR             => Net::EGTS::Record->new(
                SST         => EGTS_AUTH_SERVICE,
                RST         => EGTS_AUTH_SERVICE,
                RD          => Net::EGTS::SubRecord::Auth::DispatcherIdentity->new(
                    DT      => $self->type,
                    DID     => $self->did,
                    DSCR    => $self->description,
                )->encode,
            )->encode,
        );
        unless( my $res = print {$self->socket} $auth->encode ) {
            return 'Send error';
        }

        unless( my $res = $self->_response($auth) ) {
            $result = $res;
            next;
        }

        $result = $self;
        last;
    }

    return $result;
}

=head2 posdata $data

Send telemetry data

=cut

sub posdata {
    my ($self, $data) = @_;
    use bytes;

    my $oid = delete $data->{id};
    croak "id required" unless $oid;

    my $result;
    for(my $i = $self->attempts; $i > 0; $i-- ) {

        my $pd = Net::EGTS::Packet::Appdata->new(
            PRIORITY        => 0b11,
            SDR             => Net::EGTS::Record->new(
                OID         => $oid,
                SST         => EGTS_TELEDATA_SERVICE,
                RST         => EGTS_TELEDATA_SERVICE,
                RD          => Net::EGTS::SubRecord::Teledata::PosData->new(
                    %$data,
                )->encode,
            )->encode,
        );
        unless( my $res = print {$self->socket} $pd->encode ) {
            return 'Send error';
        }

        unless( my $res = $self->_response($pd) ) {
            $result = $res;
            next;
        }

        $result = $self;
        last;
    }

    return $result;
}

__PACKAGE__->meta->make_immutable();
