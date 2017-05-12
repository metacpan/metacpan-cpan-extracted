#!/usr/bin/perl -w
package Net::BitTorrent::Peer;
{
    use strict;
    use warnings;
    use Carp qw[carp];
    use Scalar::Util qw[blessed weaken refaddr];
    use List::Util qw[sum max];
    use Socket qw[/F_INET/ SOMAXCONN SOCK_STREAM /inet_/ /pack_sockaddr_in/];
    use Fcntl qw[F_SETFL O_NONBLOCK];
    use Math::BigInt;
    use Digest::SHA qw[sha1];
    use version qw[qv];
    our $VERSION_BASE = 52; our $UNSTABLE_RELEASE = 0; our $VERSION = sprintf(($UNSTABLE_RELEASE ? q[%.3f_%03d] : q[%.3f]), (version->new(($VERSION_BASE))->numify / 1000), $UNSTABLE_RELEASE);
    use vars qw[@EXPORT_OK %EXPORT_TAGS];
    use Exporter qw[];
    *import = *import = *Exporter::import;
    @EXPORT_OK = qw[
        DISCONNECT_BY_REMOTE           DISCONNECT_LOOPBACK
        DISCONNECT_NO_SUCH_TORRENT     DISCONNECT_HANDSHAKE_INFOHASH
        DISCONNECT_MALFORMED_HANDSHAKE DISCONNECT_MALFORMED_PACKET
        DISCONNECT_PREXISTING          DISCONNECT_TOO_MANY
        DISCONNECT_HASHCHECKING        DISCONNECT_SEED
        DISCONNECT_TIMEOUT_HANDSHAKE   DISCONNECT_USELESS_PEER
        DISCONNECT_HANDSHAKE_SYNC_DH5  ];
    %EXPORT_TAGS = (
        all        => [@EXPORT_OK],
        disconnect => [
            qw[ DISCONNECT_BY_REMOTE           DISCONNECT_LOOPBACK
                DISCONNECT_NO_SUCH_TORRENT     DISCONNECT_HANDSHAKE_INFOHASH
                DISCONNECT_MALFORMED_HANDSHAKE DISCONNECT_MALFORMED_PACKET
                DISCONNECT_PREXISTING          DISCONNECT_TOO_MANY
                DISCONNECT_HASHCHECKING        DISCONNECT_SEED
                DISCONNECT_TIMEOUT_HANDSHAKE   DISCONNECT_USELESS_PEER
                DISCONNECT_HANDSHAKE_SYNC_DH5  ]
        ],
    );
    use lib q[../../../lib];
    use Net::BitTorrent::Protocol qw[:build parse_packet :types];
    use Net::BitTorrent::Util qw[:bencode];
    use Net::BitTorrent::Version;
    my (@CONTENTS) = \my (
        %_client,           %_socket,         %torrent,
        %_data_out,         %_data_in,        %peerid,
        %bitfield,          %am_choking,      %am_interested,
        %peer_choking,      %peer_interested, %incoming,
        %requests_out,      %requests_in,     %_last_contact,
        %_incoming_fastset, %reserved_bytes,  %source,
        %host,              %port,
        #################### Alpha code:
        %_RC4_S, %_crypto_select, %_S,  %_i, %_j, %_state,
        %_Xa,    %_Ya,            %_Yb, %_Xb,
        %_KeyA,  %_KeyB,          %_parse_packets_schedule
    );
    my %REGISTRY;
    my %_Disconnect_Strings = (
        DISCONNECT_BY_REMOTE() =>
            q[Connection closed by remote peer],    # or unknown
        DISCONNECT_LOOPBACK()        => q[...we've connected to ourself.],
        DISCONNECT_NO_SUCH_TORRENT() => q[We aren't serving this torrent]
        ,                                   # comes with { Infohash => [...] }
        DISCONNECT_HANDSHAKE_INFOHASH() =>
            q[Bad plaintext handshake (Incorrect Infohash)],
        DISCONNECT_MALFORMED_HANDSHAKE() => q[Bad plaintext handshake],
        DISCONNECT_MALFORMED_PACKET()    => q[...bad packet.],
        DISCONNECT_PREXISTING()          => q[Already connected to this peer]
        ,                                   # comes with { PeerID => [...] }
        DISCONNECT_TOO_MANY()     => q[Enough peers already!],
        DISCONNECT_HASHCHECKING() => q[Hash checking],
        DISCONNECT_SEED()         => q[Disconnect seed],
        -26                       => q[Handed a piece we never asked for]
        ,    # { Index => \d, Offset => \d, Length=> \d }
        -28 => q[Sent a reject to a non-existant piece],
        -29 => q[Rejected a request we never made.],
        DISCONNECT_TIMEOUT_HANDSHAKE() =>
            q[Failed to complete handshake within 30s],
        -40 => q[Peer is idle],
        DISCONNECT_USELESS_PEER() =>
            q[Useless peer (Not interested and not interesting.)],
        -101                            => q[Bad VC in encrypted handshake],
        DISCONNECT_HANDSHAKE_SYNC_DH5() => q[Failed to sync DH-5],
        -103                            => q[Bad encrypted header at stage 4],
        -104 => q[Bad encrypted handshake (Bad SKEY)],
        -105 => q[Unsupported encryption scheme]
    );
    sub DISCONNECT_BY_REMOTE           {0}
    sub DISCONNECT_LOOPBACK            {-10}
    sub DISCONNECT_NO_SUCH_TORRENT     {-11}
    sub DISCONNECT_HANDSHAKE_INFOHASH  {-12}
    sub DISCONNECT_MALFORMED_HANDSHAKE {-13}
    sub DISCONNECT_MALFORMED_PACKET    {-22}
    sub DISCONNECT_PREXISTING          {-16}
    sub DISCONNECT_TOO_MANY            {-17}
    sub DISCONNECT_HASHCHECKING        {-18}
    sub DISCONNECT_SEED                {-25}
    sub DISCONNECT_TIMEOUT_HANDSHAKE   {-30}
    sub DISCONNECT_USELESS_PEER        {-41}
    sub DISCONNECT_HANDSHAKE_SYNC_DH5  {-102}

    # States
    sub MSE_ONE   {1}
    sub MSE_TWO   {2}
    sub MSE_THREE {3}
    sub MSE_FOUR  {4}
    sub MSE_FIVE  {5}
    sub REG_ONE   {11}
    sub REG_TWO   {12}
    sub REG_THREE {13}
    sub REG_OKAY  {100}

    #
    sub CRYPTO_PLAIN {0x01}
    sub CRYPTO_RC4   {0x02}
    sub CRYPTO_XOR   {0x04}    # unimplemented
    sub CRYPTO_AES   {0x08}    # unimplemented

    sub DH_P {
        return Math::BigInt->new(
            q[0xFFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A63A36210000000000090563]
        );
    }
    sub DH_G {2}
    sub VC   { qq[\0] x 8 }

    sub crypto_provide {
        return pack q[N],
            CRYPTO_PLAIN       # | CRYPTO_RC4    #| CRYPTO_XOR | CRYPTO_AES;
    }
    sub len { pack(q[n], length(shift)) }

    sub new {

        # warn((caller(0))[3]);
        my ($class, $args) = @_;
        my $self = undef;
        if (not defined $args) {
            carp q[Net::BitTorrent::Peer->new({ }) requires ]
                . q[parameters a hashref];
            return;
        }
        if (    !$args->{q[Socket]}
            and !$args->{q[Address]})
        {   carp <<'END'; return; }
Net::BitTorrent::Peer->new({}) requires either...
  - an 'Address' (IPv4:port for new, outgoing connections)
    or
  - a 'Socket' (GLOB-type for newly accepted incoming connections)
END
        if ($args->{q[Socket]}) {
            if (ref($args->{q[Socket]}) ne q[GLOB]) {
                carp
                    q[Net::BitTorrent::Peer->new({ }) requires a GLOB-type socket];
                return;
            }
            if (   (!$args->{q[Client]})
                || (!blessed $args->{q[Client]})
                || (!$args->{q[Client]}->isa(q[Net::BitTorrent])))
            {   carp
                    q[Net::BitTorrent::Peer->new({ }) requires a blessed Net::BitTorrent object in the 'Client' parameter];
                return;
            }
            my ($port, $packed_ip)
                = unpack_sockaddr_in(getpeername($args->{q[Socket]}));
            my $ok = $args->{q[Client]}->_event(q[ip_filter],
                {Address => sprintf(q[%s:%d], inet_ntoa($packed_ip), $port)});
            if (defined $ok and $ok == 0) { return; }
            my $ip = inet_ntoa($packed_ip);
            if (scalar(
                    grep {
                               $_->{q[Object]}->isa(q[Net::BitTorrent::Peer])
                            && $_->{q[Object]}->host
                            && $_->{q[Object]}->host eq $ip
                            && $_->{q[Object]}->port
                            && $_->{q[Object]}->port eq $port
                        } values %{$args->{q[Client]}->_connections}
                ) > $args->{q[Client]}->_connections_per_host
                )
            {   shutdown($args->{q[Socket]}, 2);
                close($args->{q[Socket]});
                return;
            }
            $self
                = bless \sprintf(q[%s:%d], $ip, $port),
                $class;
            $_socket{refaddr $self} = $args->{q[Socket]};
            $_client{refaddr $self} = $args->{q[Client]};
            weaken $_client{refaddr $self};
            $_client{refaddr $self}->_add_connection($self, q[ro]) or return;
            $_data_out{refaddr $self} = q[];
            $_data_in{refaddr $self}  = q[];
            $incoming{refaddr $self}  = 1;
            $source{refaddr $self}    = q[Incoming];
            $_state{refaddr $self} = (
                                     $_client{refaddr $self}->_encryption_mode
                                     ? MSE_TWO
                                     : REG_TWO
            );
        }
        else {
            if ($args->{q[Address]}
                !~ m[^(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]?){4}):\d+$]
                )
            {   carp
                    q[Net::BitTorrent::Peer->new({ }) requires an IPv4:port 'Address'];
                return;
            }
            if (   (!$args->{q[Torrent]})
                || (!blessed $args->{q[Torrent]})
                || (!$args->{q[Torrent]}->isa(q[Net::BitTorrent::Torrent])))
            {   carp
                    q[Net::BitTorrent::Peer->new({ }) requires a blessed 'Torrent'];
                return;
            }
            if (!$args->{q[Source]}) {
                carp
                    q[Net::BitTorrent::Peer->new({ }) would like to know where this peer info is from];
                return;
            }
            my $half_open = grep {
                $_->{q[Object]}->isa(q[Net::BitTorrent::Peer])
                    && !$_->{q[Object]}->torrent
            } values %{$args->{q[Torrent]}->_client->_connections};
            if ($half_open >= $args->{q[Torrent]}->_client->_half_open) {

                #warn sprintf q[%d half open sockets!], $half_open;
                return;
            }
            if (scalar($args->{q[Torrent]}->peers)
                >= $args->{q[Torrent]}->_client->_peers_per_torrent)
            {   return;
            }
            my ($_host, $_port) = split q[:], $args->{q[Address]}, 2;
            if (scalar(
                    grep {
                               $_->{q[Object]}->isa(q[Net::BitTorrent::Peer])
                            && $_->{q[Object]}->host
                            && $_->{q[Object]}->host eq $_host
                            && $_->{q[Object]}->port
                            && $_->{q[Object]}->port == $_port
                        } values %{$args->{q[Torrent]}->_client->_connections}
                ) > $args->{q[Torrent]}->_client->_connections_per_host
                )
            {   return;
            }
            socket(my ($socket), PF_INET, SOCK_STREAM, getprotobyname(q[tcp]))
                or return;
            $self = bless \$args->{q[Address]}, $class;
            ($host{refaddr $self}, $port{refaddr $self}) = ($_host, $_port);
            $_socket{refaddr $self} = $socket;
            if (not($^O eq q[MSWin32]    # set non blocking
                    ? ioctl($_socket{refaddr $self}, 0x8004667e,
                            pack(q[I], 1))
                    : fcntl($_socket{refaddr $self}, F_SETFL, O_NONBLOCK)
                )
                )
            {   return;
            }
            connect($_socket{refaddr $self},
                    pack_sockaddr_in($port{refaddr $self},
                                     inet_aton($host{refaddr $self})
                    )
            );
            $_client{refaddr $self} = $args->{q[Torrent]}->_client;
            weaken $_client{refaddr $self};
            $torrent{refaddr $self} = $args->{q[Torrent]};
            weaken $torrent{refaddr $self};
            ${$bitfield{refaddr $self}}
                = pack(q[b*], qq[\0] x $torrent{refaddr $self}->piece_count);
            my %_payload = (
                  Reserved => $_client{refaddr $self}->_build_reserved,
                  Infohash => pack(q[H40], $torrent{refaddr $self}->infohash),
                  PeerID   => $_client{refaddr $self}->peerid
            );

            if (   ($_client{refaddr $self}->_encryption_mode != 0x00)
                && (!$args->{q[_plaintext]})    # XXX
                )
            {   $_state{refaddr $self} = MSE_ONE;
            }
            else {
                $_state{refaddr $self} = REG_ONE;
            }
            $_data_in{refaddr $self} = q[];
            $_client{refaddr $self}->_add_connection($self, q[wo]) or return;
            $incoming{refaddr $self} = 0;
            $source{refaddr $self}   = $args->{q[Source]};
        }
        if ($self) {
            ${$am_choking{refaddr $self}}      = 1;
            ${$am_interested{refaddr $self}}   = 0;
            ${$peer_choking{refaddr $self}}    = 1;
            ${$peer_interested{refaddr $self}} = 0;
            ${$bitfield{refaddr $self}} ||= ();
            $_last_contact{refaddr $self}  = time;            # lies
            $_crypto_select{refaddr $self} = CRYPTO_PLAIN;    # passthrough
            $requests_out{refaddr $self}   = [];
            $requests_in{refaddr $self}    = [];
            $_client{refaddr $self}->_schedule({Time   => time + 120,
                                                Code   => \&_send_keepalive,
                                                Object => $self
                                               }
            );
            $_client{refaddr $self}->_schedule(
                                           {Time   => time + 30,
                                            Code   => \&_cancel_old_requests,
                                            Object => $self
                                           }
            );
            $_client{refaddr $self}->_schedule(
                                       {Time   => time + 90,
                                        Code   => \&_disconnect_useless_peer,
                                        Object => $self
                                       }
            );
            $_client{refaddr $self}->_schedule(
                {   Time => time + 30,
                    Code => sub {
                        my $s = shift;
                        if (!$peerid{refaddr $s}) {
                            weaken $s;
                            $s->_disconnect(DISCONNECT_TIMEOUT_HANDSHAKE);
                            if ((!$incoming{refaddr $self}
                                )    # outgoing connection
                                 #&& ($_crypto_select{refaddr $self} != CRYPTO_PLAIN)
                                && ($torrent{refaddr $self})
                                && ($_state{refaddr $self} < REG_ONE)
                                )
                            {

                                #warn q[RETRY! :D];
                                my $peer =    # retry unencrypted
                                    Net::BitTorrent::Peer->new(
                                    {   Address => (
                                                sprintf q[%s:%d], $self->host,
                                                $self->port
                                        ),
                                        Torrent => $torrent{refaddr $self},
                                        Source  => q[TODO],
                                        _plaintext => 1    # XXX
                                    }
                                    );
                            }
                        }
                        return 1;
                    },
                    Object => $self
                }
            );
            $_client{refaddr $self}->_schedule(
                {   Time => time + 1,
                    Code => sub {
                        my $s = shift;
                        return $s->_parse_packets;
                    },
                    Object => $self
                }
            );
            if ($threads::shared::threads_shared) {
                threads::shared::share($bitfield{refaddr $self})
                    if defined $bitfield{refaddr $self};
                threads::shared::share($am_choking{refaddr $self});
                threads::shared::share($am_interested{refaddr $self});
                threads::shared::share($peer_choking{refaddr $self});
                threads::shared::share($peer_interested{refaddr $self});
            }
            weaken($REGISTRY{refaddr $self} = $self);
        }
        return $self;
    }

    # Accessors | Public | General
    sub peerid { return $peerid{refaddr +shift}; }

    # Accessors | Private | General
    sub _socket        { return $_socket{refaddr +shift}; }
    sub torrent        { return $torrent{refaddr +shift}; }
    sub reserved_bytes { return $reserved_bytes{refaddr +shift}; }
    sub bitfield       { return ${$bitfield{refaddr +shift}}; }

    sub port {
        return if defined $_[1];
        my ($self) = @_;
        if (!$port{refaddr $self}) {
            return if not defined $_socket{refaddr $self};
            my $peername = getpeername($_socket{refaddr $self});
            return if not defined $peername;
            ($port{refaddr $self}, undef) = unpack_sockaddr_in($peername);
        }
        return $port{refaddr $self};
    }

    sub host {
        return if defined $_[1];
        my ($self) = @_;
        if (!$host{refaddr $self}) {
            return if not defined $_socket{refaddr $self};
            my $peername = getpeername($_socket{refaddr $self});
            return if not defined $peername;
            my (undef, $packed_ip) = unpack_sockaddr_in($peername);
            $host{refaddr $self} = inet_ntoa($packed_ip);
        }
        return $host{refaddr $self};
    }

    # Accessors | Private | Status
    sub peer_choking    { return ${$peer_choking{refaddr +shift}}; }
    sub am_choking      { return ${$am_choking{refaddr +shift}}; }
    sub peer_interested { return ${$peer_interested{refaddr +shift}}; }
    sub am_interested   { return ${$am_interested{refaddr +shift}}; }
    sub incoming        { return $incoming{refaddr +shift}; }
    sub source          { return $source{refaddr +shift}; }

    # Methods | Private
    sub _rw {

        # warn((caller(0))[3]);
        my ($self, $read, $write, $error) = @_;

        #Carp::cluck sprintf q[%s->_rw(%d, %d, %d) | %d], __PACKAGE__, $read,
        #    $write, $error, $_state{refaddr $self};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT);
            return;
        }
        if ($error) {
            weaken $self;
            $self->_disconnect($^E);
            return;
        }
        if (defined $torrent{refaddr $self}
            and $torrent{refaddr $self}->status & 2)
        {   weaken $self;
            $self->_disconnect(DISCONNECT_HASHCHECKING);
            return;
        }
        my ($actual_read, $actual_write) = (0, 0);
        if ($read) {
            if (   ($_crypto_select{refaddr $self} == CRYPTO_RC4)
                && ($_state{refaddr $self} >= REG_ONE))
            {   $actual_read
                    = sysread($_socket{refaddr $self}, my ($data_in), $read);
                $_data_in{refaddr $self} .=
                    $self->_RC4((   $incoming{refaddr $self}
                                  ? $_KeyA{refaddr $self}
                                  : $_KeyB{refaddr $self}
                                ),
                                $data_in
                    );

                #warn $data_in;
                #use Data::Dump qw[pp];
                #warn pp $_data_in{refaddr $self};
                #warn $_data_in{refaddr $self};
            }
            else {

                #warn q[Reading plaintext data];
                $actual_read = sysread($_socket{refaddr $self},
                                       $_data_in{refaddr $self},
                                       $read,
                                       length($_data_in{refaddr $self})
                );
            }
            if (!$actual_read) {
                weaken $self;
                $self->_disconnect($^E);
                return;
            }

            #warn sprintf q[Read %d bytes of data], $actual_read;
            $_last_contact{refaddr $self} = time;
            if (!$peerid{refaddr $self}) {
                $_client{refaddr $self}
                    ->_event(q[peer_connect], {Peer => $self});
            }
            $_client{refaddr $self}->_event(q[peer_read],
                                     {Peer => $self, Length => $actual_read});
        }
        if ($write && $_data_out{refaddr $self}) {
            $actual_write =
                syswrite($_socket{refaddr $self},
                         $_data_out{refaddr $self},
                         $write, 0);

            #warn sprintf q[Wrote %d bytes of data], $actual_write;
            if (not $actual_write) {
                weaken $self;
                $self->_disconnect($^E);
                return;
            }
            else {
                $_client{refaddr $self}->_event(q[peer_write],
                                    {Peer => $self, Length => $actual_write});
                substr($_data_out{refaddr $self}, 0, $actual_write, q[]);
            }
        }

        #$_client{refaddr $self}->_add_connection($self, q[rw]);
        return ($actual_read, $actual_write);
    }

    sub _syswrite {    # applies any encryption
        my ($self, $data) = @_;
        return if !$data;

        #warn sprintf q[Sending %d bytes], length($data);
        if (   ($_crypto_select{refaddr $self} == CRYPTO_RC4)
            && ($_state{refaddr $self} >= REG_ONE))
        {   $data = $self->_RC4((  $incoming{refaddr $self}
                                 ? $_KeyB{refaddr $self}
                                 : $_KeyA{refaddr $self}
                                ),
                                $data
            );
        }
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return length($_data_out{refaddr $self} .= $data);
    }
    my %_parse_packets_handshake_dispatch = (
                          &MSE_ONE   => \&___handle_encrypted_handshake_one,
                          &MSE_TWO   => \&___handle_encrypted_handshake_two,
                          &MSE_THREE => \&___handle_encrypted_handshake_three,
                          &MSE_FOUR  => \&___handle_encrypted_handshake_four,
                          &MSE_FIVE  => \&___handle_encrypted_handshake_five,
                          &REG_ONE   => \&___handle_plaintext_handshake_one,
                          &REG_TWO   => \&___handle_plaintext_handshake_two,
                          &REG_THREE => \&___handle_plaintext_handshake_three
    );
    my %_parse_packets_dispatch = (
                                 &KEEPALIVE      => \&__handle_keepalive,
                                 &CHOKE          => \&__handle_choke,
                                 &UNCHOKE        => \&__handle_unchoke,
                                 &INTERESTED     => \&__handle_interested,
                                 &NOT_INTERESTED => \&__handle_not_interested,
                                 &HAVE           => \&__handle_have,
                                 &BITFIELD       => \&__handle_bitfield,
                                 &REQUEST        => \&__handle_request,
                                 &PIECE          => \&__handle_piece,
                                 &CANCEL         => \&__handle_cancel,
                                 &HAVE_ALL       => \&__handle_have_all,
                                 &HAVE_NONE      => \&__handle_have_none,
                                 &ALLOWED_FAST   => \&__handle_allowed_fast,
                                 &REJECT         => \&__handle_reject,
                                 &EXTPROTOCOL    => \&__handle_ext_protocol
    );

    sub _parse_packets {
        my ($self, $time) = @_;

        #warn((caller(0))[3] . q[ | ] . $_state{refaddr $self}) . q[ | ]
        #    . ($peerid{refaddr $self} || q[Unknown]);
        #warn q[$_state{refaddr $self} == ] . $_state{refaddr $self};
        if ($_state{refaddr $self} != REG_OKAY) {
            if (defined
                $_parse_packets_handshake_dispatch{$_state{refaddr $self}})
            {   $_parse_packets_handshake_dispatch{$_state{refaddr $self}}(
                                                                       $self);
            }
            else {
                Carp::cluck q[Unknown state: ] . $_state{refaddr $self};
            }
        }
        elsif (length $_data_in{refaddr $self}) {
        PACKET: while ($_data_in{refaddr $self}) {
                my $data_len = length $_data_in{refaddr $self};
                my $packet   = parse_packet(\$_data_in{refaddr $self});

                #use Data::Dump qw[pp];
                #warn pp $packet;
                if (!$packet) {
                    if (length($_data_in{refaddr $self}) != $data_len) {

                        # N::B::Protocol removed some data but couldn't parse
                        #   a packet from what was removed. Gotta be bad data.
                        weaken $self;
                        $self->_disconnect(DISCONNECT_MALFORMED_PACKET);
                        return;
                    }
                    last PACKET;
                }
                if (defined $_parse_packets_dispatch{$packet->{q[Type]}}) {
                    $_parse_packets_dispatch{$packet->{q[Type]}}($self,
                                                       $packet->{q[Payload]});
                }
                else {
                    my $packet_dump = q[];
                    if (eval require Data::Dump) {    # I like this better
                        $packet_dump = Data::Dump::pp($packet);
                    }
                    else {    # fallback to lame core module
                        require Data::Dumper;
                        $packet_dump = Data::Dumper::Dumper($packet);
                    }
                    Carp::carp
                        sprintf <<'END', $self->as_string(1), $packet_dump;
------------------------------------------------------------------------------
Unknown incoming packet. This may be a bug in Net::BitTorrent, so please c+p
the following block when you report this in the Net::BitTorrent Issue Tracker:
http://github.com/sanko/net-bittorrent/issues
------------------------------------------------------------------------------
= Peer Information ===========================================================
%s
= Packet Information =========================================================
%s
------------------------------------------------------------------------------
See the "Issue Tracker" section in 'perldoc Net::BitTorrent::Notes' for more
information. Thanks!
------------------------------------------------------------------------------
END
                }
            }
        }
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        $_parse_packets_schedule{refaddr $self}
            = $_client{refaddr $self}->_schedule({Time   => time + 3,
                                                  Code   => \&_parse_packets,
                                                  Object => $self
                                                 }
            ) if !$time;
        return 1;
    }

    sub ___handle_encrypted_handshake_one {

        # warn((caller(0))[3]);
        my ($self) = @_;

        # Encryption is enabled
        # Step 1A:
        #  - Generate Ya, PadA
        #  - Send Ya, PadA to B
        $_Xa{refaddr $self} = int rand(9999999999999999);
        $_Ya{refaddr $self}
            = Math::BigInt->new(DH_G)->bmodpow($_Xa{refaddr $self}, DH_P);
        my @bits
            = map { chr hex $_ } ($_Ya{refaddr $self}->as_hex =~ m[(..)]g);
        shift @bits;

        #warn sprintf q[Step 1A Complete: %s | %d bytes in cache],
        #$self->as_string,
        $self->_syswrite(join q[], @bits,
                         (map { chr rand(255) } 1 .. int(rand 512)));
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        $_state{refaddr $self} = MSE_THREE;
        return 1;
    }

    sub ___handle_encrypted_handshake_two {

        # warn((caller(0))[3]);
        my ($self) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        if ($_data_in{refaddr $self} =~ m[^\x13BitTorrent protocol.{48}$]s) {

            #warn q[Switching to plaintext handshake];
            $_state{refaddr $self} = REG_TWO;
            return;
        }

        # Step 2B:
        #  - Read Ya from A
        #  - Generate Yb, PadB
        #  - Generate S
        #  - Send Yb, PadB to A
        if (length($_data_in{refaddr $self}) < 96) {

            #warn sprintf
            #    q[Not enough data for Step 2B (req: 96, have: %d)],
            #    length($_data_in{refaddr $self});
            $_client{refaddr $self}->_add_connection($self, q[rw]);
            return 1;
        }
        $_Ya{refaddr $self} = Math::BigInt->new(
            join q[],    # Read Ya from A
            q[0x],
            map { sprintf q[%02x], ord $_ } split //,
            substr($_data_in{refaddr $self}, 0, 96, q[])
        );
        $_Xb{refaddr $self} = int rand(9999999999999999);    # Random Xb
        $_Yb{refaddr $self}
            = Math::BigInt->new(DH_G)->bmodpow($_Xb{refaddr $self}, DH_P);
        my @bits
            = map { chr hex $_ }
            ($_Ya{refaddr $self}->bmodpow($_Xb{refaddr $self}, DH_P)->as_hex
             =~ m[(..)]g);
        shift @bits;
        $_S{refaddr $self} = join q[], @bits;
        my @_bits
            = map { chr hex $_ } ($_Yb{refaddr $self}->as_hex =~ m[(..)]g);
        shift @_bits;
        $self->_syswrite(
                  join(q[], @_bits)
                . join(q[], map { chr int rand(255) } 1 .. (rand(1024) % 512))
        );

        #warn sprintf q[Step 2B Complete: %s | %d bytes in cache],
        #    $self->as_string,
        $self->_syswrite(
                  join(q[], @_bits)
                . join(q[], map { chr int rand(255) } 1 .. (rand(1024) % 512))
        );
        $_state{refaddr $self} = MSE_FOUR;
        return 1;
    }

    sub ___handle_encrypted_handshake_three {

        # warn((caller(0))[3]);
        my ($self) = @_;

        # Step 3A:
        #  - Read Yb from B
        #  - Generate S
        #  - Generate SKEY
        #  - Send HASH('req1', S)
        #  - Send HASH('req2', SKEY) xor HASH('req3', S)
        #  - Generate PadC, IA, SKEY
        #  - Send ENCRYPT(VC, crypto_provide, len(PadC), PadC, len(IA))
        #  - Send ENCRYPT(IA)
        if (length($_data_in{refaddr $self}) < 96) {

            #warn sprintf
            #    q[Not enough data for Step 3A (req: 96, have: %d)],
            #    length($_data_in{refaddr $self});
            $_client{refaddr $self}->_add_connection($self, q[rw]);
            return 1;
        }
        $_Yb{refaddr $self} =
            Math::BigInt->new(join q[],
                              q[0x],
                              map { sprintf q[%02x], ord $_ }
                                  split //,
                              substr($_data_in{refaddr $self}, 0, 96, q[])
            );
        my @bits
            = map { chr hex $_ }
            ($_Yb{refaddr $self}->bmodpow($_Xa{refaddr $self}, DH_P)->as_hex
             =~ m[(..)]g);
        shift @bits;
        $_S{refaddr $self} = join q[], @bits;
        $torrent{refaddr $self} || return 0;  # XXX - Local error. Disconnect?
        $_KeyA{refaddr $self}
            = sha1(  q[keyA]
                   . $_S{refaddr $self}
                   . pack(q[H*], $torrent{refaddr $self}->infohash));

        # first piece: HASH('req1' . S)
        $self->_syswrite(sha1(q[req1] . $_S{refaddr $self}));

        # second piece: HASH('req2', SKEY) xor HASH('req3', S)
        $self->_syswrite(
                sha1(q[req2] . pack(q[H*], $torrent{refaddr $self}->infohash))
                    ^ sha1(q[req3] . $_S{refaddr $self}));

        # third piece: ENCRYPT(VC, crypto_provide, len(PadC), PadC, len(IA))
        my $PadC = q[];
        my $IA   = q[];
        $self->_RC4($_KeyA{refaddr $self}, q[ ] x 1024, 1);
        $self->_syswrite(
            $self->_RC4(
                $_KeyA{refaddr $self},
                VC                       # 64 | 8
                    . crypto_provide     # 32 | 4
                    . len($PadC)         # 16 | 2
                    . $PadC              # '' | 0
                    . len($IA)           # 16 | 2
            )
        );

        # fouth piece: ENCRYPT(IA)
        $self->_syswrite($self->_RC4($_KeyA{refaddr $self}, $IA));

        #warn q[Step 3A Complete ] . $self->as_string;
        $_state{refaddr $self} = MSE_FIVE;
        return 1;
    }

    sub ___handle_encrypted_handshake_four {

        #warn((caller(0))[3]);
        my ($self) = @_;
        if (length($_data_in{refaddr $self}) < 40) {

            #warn sprintf
            #    q[Not enough data for Step 4B (req: 40, have: %d)],
            #    length($_data_in{refaddr $self});
            $_client{refaddr $self}->_add_connection($self, q[rw]);
            return 1;
        }

        # Step 4B:
        # - Sync on sha1('req1', S)
        # - Get !req2|req3
        # - Locate torrent
        # - Disconnect if we aren't serving this torrent
        # - Get crypto_provide (requires decode)
        # - Decide on an encryption scheme
        # - Generate PadD
        # - Send ENCRYPT(VC, crypto_select, len(padD), padD)
        # - Send ENCRYPT2(Payload Stream)
        if (index($_data_in{refaddr $self}, sha1(q[req1], $_S{refaddr $self})
            ) == -1
            )
        {   $_client{refaddr $self}->_add_connection($self, q[rw]);
            return;
        }
        substr(    # Sync on sha1(q[req1], $Ali{q[S]})
            $_data_in{refaddr $self},
            0,
            index($_data_in{refaddr $self}, sha1(q[req1], $_S{refaddr $self})
            ),
            q[]
        );
        my $req1      = substr($_data_in{refaddr $self}, 0, 20, q[]);
        my $req2_req3 = substr($_data_in{refaddr $self}, 0, 20, q[]);
    INFOHASH:
        for my $torrent (values %{$_client{refaddr $self}->torrents}) {
            if ((sha1(q[req2], pack q[H*], $torrent->infohash)
                 ^ sha1(q[req3], $_S{refaddr $self})
                ) eq $req2_req3
                )
            {   $torrent{refaddr $self} = $torrent;
                weaken $torrent{refaddr $self};
                ${$bitfield{refaddr $self}} = pack(q[b*],
                               qq[\0] x $torrent{refaddr $self}->piece_count);
                last INFOHASH;
            }
        }
        if (!$torrent{refaddr $self}) {
            $self->_disconnect(-103);
            return;
        }
        if (!$torrent{refaddr $self}) {
            $self->_disconnect(-104);
            return;
        }
        $_KeyB{refaddr $self}
            = sha1(  q[keyB]
                   . $_S{refaddr $self}
                   . pack(q[H*], $torrent{refaddr $self}->infohash));
        $_KeyA{refaddr $self}
            = sha1(  q[keyA]
                   . $_S{refaddr $self}
                   . pack(q[H*], $torrent{refaddr $self}->infohash));
        $self->_RC4($_KeyA{refaddr $self}, q[ ] x 1024, 1);
        my ($VC, $crypto_provide, $len_padC, $PadC, $len_IA)
            = ($self->_RC4($_KeyA{refaddr $self},
                           substr($_data_in{refaddr $self}, 0, 16, q[]))
                   =~ m[^(.{8})(....)(..)()(..)$]
            );
        if (!($VC && $crypto_provide)) {    # XXX - Hmmm...
                #$self->_disconnect(DISCONNECT_HANDSHAKE_DH4);
            return;
        }

        # Prioritize encryption schemes: RC4, plaintext, XOR , ...
        # XXX - Allow the user to set the order
        if (unpack(q[N], $crypto_provide) & CRYPTO_RC4) {
            $_crypto_select{refaddr $self} = CRYPTO_RC4;
        }
        elsif (unpack(q[N], $crypto_provide) & CRYPTO_PLAIN) {
            $_crypto_select{refaddr $self} = CRYPTO_PLAIN;
        }

        #elsif (unpack(q[N], $crypto_provide) & CRYPTO_XOR) {
        #    $_crypto_select{refaddr $self} = CRYPTO_XOR;
        #}
        #elsif (unpack(q[N], $crypto_provide) & CRYPTO_AES) {
        #    $_crypto_select{refaddr $self} = CRYPTO_AES;
        #}
        else {
            weaken $self;
            $self->_disconnect(-105);
            return;
        }
        my $IA
            = substr($_data_in{refaddr $self}, 0, unpack(q[n], $len_IA), q[]);
        if ($IA) {
            if ($_crypto_select{refaddr $self} = CRYPTO_RC4) {
                $IA = $self->_RC4($_KeyA{refaddr $self}, $IA);
            }
            $_data_in{refaddr $self} = $IA;
        }

        # reset for ENCRYPT2
        $self->_RC4($_KeyB{refaddr $self}, q[ ] x 1024, 1);

        # Send ENCRYPT(VC, crypto_select, len(padD), padD)
        my $PadD = q[];
        $self->_syswrite(
                  $self->_RC4($_KeyB{refaddr $self},
                              VC
                                  . pack(q[N], $_crypto_select{refaddr $self})
                                  . len($PadD)
                                  . $PadD
                  )
        );
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        $_state{refaddr $self} = REG_TWO;
        return 1;
    }

    sub ___handle_encrypted_handshake_five {

        #warn((caller(0))[3]);
        my ($self) = @_;
        if (length($_data_in{refaddr $self}) < 34) {

            #warn sprintf q[Not enough data for enc five (req: 34, have: %d)],
            #    length($_data_in{refaddr $self});
            $_client{refaddr $self}->_add_connection($self, q[rw]);
            return;
        }

        # Step 5A:
        # - Synch on ENCRYPT(VC)
        # - Find crypto_select
        # -
        # - Send ENCRYPT2(Payload Stream)
        $_KeyB{refaddr $self}
            = sha1(  q[keyB]
                   . $_S{refaddr $self}
                   . pack(q[H40], $torrent{refaddr $self}->infohash));
        $self->_RC4($_KeyB{refaddr $self}, q[ ] x 1024, 1);
        my $index = index($_data_in{refaddr $self},
                          $self->_RC4($_KeyB{refaddr $self}, VC));
        if ($index == -1) {
            if (length($_data_in{refaddr $self}) >= 628) {
                $self->_disconnect(DISCONNECT_HANDSHAKE_SYNC_DH5);
                my $peer =    # retry unencrypted
                    Net::BitTorrent::Peer->new(
                    {   Address =>
                            (sprintf q[%s:%d], $self->host, $self->port),
                        Torrent    => $torrent{refaddr $self},
                        Source     => q[TODO],
                        _plaintext => 1                          # XXX
                    }
                    ) if !$incoming{refaddr $self};
            }
            else {
                $_client{refaddr $self}->_add_connection($self, q[rw]);
            }
            return;
        }
        substr($_data_in{refaddr $self}, 0, $index, q[]);
        $self->_RC4($_KeyB{refaddr $self}, q[ ] x 1024, 1);
        my ($VC, $crypto_select, $len_PadD) = (
            $self->_RC4(    # Find crypto_select
                $_KeyB{refaddr $self},
                substr($_data_in{refaddr $self}, 0, 14, q[])
                ) =~ m[^(.{8})(....)(..)$]
        );
        if (!$VC || $VC ne VC) {
            weaken $self;
            $self->_disconnect(-101);
            my $peer =      # retry unencrypted
                Net::BitTorrent::Peer->new(
                {   Address => (sprintf q[%s:%d], $self->host, $self->port),
                    Torrent    => $torrent{refaddr $self},
                    Source     => q[TODO],
                    _plaintext => 1                          # XXX
                }
                ) if !$incoming{refaddr $self};
            return;
        }
        $_crypto_select{refaddr $self} = unpack(q[N], $crypto_select);

        #         warn q[Plain]
        #~             if $_crypto_select{refaddr $self} == CRYPTO_PLAIN;
        #~         warn q[XOR  ]
        #~             if $_crypto_select{refaddr $self} == CRYPTO_XOR;
        #~         warn q[RC4  ]
        #~             if $_crypto_select{refaddr $self} == CRYPTO_RC4;
        #~         warn q[AES  ]
        #~             if $_crypto_select{refaddr $self} == CRYPTO_AES;
        #
        substr($_data_in{refaddr $self}, 0, unpack(q[n], $len_PadD), q[]);
        if ($_crypto_select{refaddr $self} == CRYPTO_RC4) {

            # reset and prime for ENCRYPT2
            $self->_RC4($_KeyA{refaddr $self}, q[ ] x (1024 + 16), 1);

            #$self->_RC4($_KeyB{refaddr $self}, q[ ] x 1024 , 1);
        }
        if ($_data_in{refaddr $self}) {

            # XXX - Decode their IA
        }
        $_client{refaddr $self}->_add_connection($self, q[rw]);

        #warn q[Step 5A Complete: ] . $self->as_string;
        $_state{refaddr $self} = REG_ONE;
        return 1;
    }

    sub ___handle_plaintext_handshake_one {

        # warn((caller(0))[3]);
        my ($self) = @_;

        # Initiate connection by sending the plaintext handshake
        my %_payload = (
                  Reserved => $_client{refaddr $self}->_build_reserved,
                  Infohash => pack(q[H40], $torrent{refaddr $self}->infohash),
                  PeerID   => $_client{refaddr $self}->peerid
        );
        $self->_syswrite(build_handshake(
                               $_payload{q[Reserved]}, $_payload{q[Infohash]},
                               $_payload{q[PeerID]}
                         )
        );
        $_client{refaddr $self}->_event(q[outgoing_packet],
                                        {Peer    => $self,
                                         Payload => \%_payload,
                                         Type    => HANDSHAKE
                                        }
        );
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        $_state{refaddr $self} = REG_THREE;
        return 1;
    }

    sub ___handle_plaintext_handshake_two {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $_socket{refaddr $self};
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !$_data_in{refaddr $self};
        my $packet = parse_packet(\$_data_in{refaddr $self});
        return if !defined $packet;
        if ($packet->{q[Type]} != HANDSHAKE) {
            weaken $self;
            $self->_disconnect(DISCONNECT_MALFORMED_HANDSHAKE);
            return;
        }
        my $payload = $packet->{q[Payload]};
        return if !defined $payload;

        #warn q[plaintext handshake two!];
        #use Data::Dump qw[pp];
        #warn pp $packet;
        # Locate torrent or disconnect
        # Set torrent
        # Set bitfield
        # Send bitfield
        # Send ext handshake
        ($reserved_bytes{refaddr $self}, undef, $peerid{refaddr $self})
            = @{$payload};
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {
                                                    Reserved => $payload->[0],
                                                    Infohash => $payload->[1],
                                                    PeerID   => $payload->[2]
                                         },
                                         Type => HANDSHAKE
                                        }
        );
        if ($payload->[2] eq $_client{refaddr $self}->peerid) {
            weaken $self;
            $self->_disconnect(DISCONNECT_LOOPBACK);
            return;
        }
        $torrent{refaddr $self} = $_client{refaddr $self}
            ->_locate_torrent(unpack(q[H40], $payload->[1]));
        if (!defined $torrent{refaddr $self}) {
            weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT,
                               {Infohash => unpack(q[H40], $payload->[1])});
            return;
        }
        weaken $torrent{refaddr $self};
        ${$bitfield{refaddr $self}}
            = pack(q[b*], qq[\0] x $torrent{refaddr $self}->piece_count);
        if (scalar(
                grep {
                           $_->{q[Object]}->isa(q[Net::BitTorrent::Peer])
                        && $_->{q[Object]}->peerid
                        && $_->{q[Object]}->peerid eq $peerid{refaddr $self}
                    } values %{$_client{refaddr $self}->_connections}
            ) > $_client{refaddr $self}->_connections_per_host
            )
        {   $self->_disconnect(DISCONNECT_PREXISTING,
                               {PeerID => $peerid{refaddr $self}});
            return;
        }
        if (scalar($torrent{refaddr $self}->peers)
            >= $_client{refaddr $self}->_peers_per_torrent)
        {   $self->_disconnect(DISCONNECT_TOO_MANY);
            return;
        }
        if ($threads::shared::threads_shared) {
            threads::shared::share($bitfield{refaddr $self});
        }
        $_state{refaddr $self} = REG_OKAY;
        my %_payload = (
                  Reserved => $_client{refaddr $self}->_build_reserved,
                  Infohash => pack(q[H40], $torrent{refaddr $self}->infohash),
                  PeerID   => $_client{refaddr $self}->peerid
        );
        $self->_syswrite(build_handshake(
                               $_payload{q[Reserved]}, $_payload{q[Infohash]},
                               $_payload{q[PeerID]}
                         )
        );
        $_client{refaddr $self}->_event(q[outgoing_packet],
                                        {Peer    => $self,
                                         Payload => \%_payload,
                                         Type    => HANDSHAKE
                                        }
        );
        $self->_send_bitfield;
        $self->_send_extended_handshake;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        $_state{refaddr $self} = REG_OKAY;
        return 1;
    }

    sub ___handle_plaintext_handshake_three {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $_socket{refaddr $self};
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !$_data_in{refaddr $self};
        my $packet = parse_packet(\$_data_in{refaddr $self});
        return if !defined $packet;
        if ($packet->{q[Type]} != HANDSHAKE) {
            weaken $self;
            $self->_disconnect(DISCONNECT_MALFORMED_HANDSHAKE);
            return;
        }
        my $payload = $packet->{q[Payload]};
        return if !defined $payload;

        #warn q[plaintext handshake two!];
        #use Data::Dump qw[pp];
        #warn pp $packet;
        # Locate torrent or disconnect
        # Set torrent
        # Set bitfield
        # Send bitfield
        # Send ext handshake
        #
        ($reserved_bytes{refaddr $self}, undef, $peerid{refaddr $self})
            = @{$payload};
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {
                                                    Reserved => $payload->[0],
                                                    Infohash => $payload->[1],
                                                    PeerID   => $payload->[2]
                                         },
                                         Type => HANDSHAKE
                                        }
        );

        # Avoid connecting to ourselves
        if ($payload->[2] eq $_client{refaddr $self}->peerid) {
            weaken $self;
            $self->_disconnect(DISCONNECT_LOOPBACK);
            return;
        }

        # make sure the infohash is what we expect
        if ($payload->[1] ne pack q[H*], $torrent{refaddr $self}->infohash) {
            weaken $self;
            $self->_disconnect(DISCONNECT_HANDSHAKE_INFOHASH);
            return;
        }

        # Send bitfield and ext handshake before moving beyond the handshake
        #  phase
        $self->_send_bitfield;
        $self->_send_extended_handshake;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        $_state{refaddr $self} = REG_OKAY;
        return 1;
    }

    sub __handle_keepalive {

        # warn((caller(0))[3]);
        my ($self) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # XXX - this should never happen
            return;
        }
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => KEEPALIVE
                                        }
        );
        return 1;
    }

    sub __handle_choke {

        # warn((caller(0))[3]);
        my ($self) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => CHOKE
                                        }
        );
        ${$peer_choking{refaddr $self}}  = 1;
        ${$am_interested{refaddr $self}} = 0;
        for my $request (@{$requests_out{refaddr $self}}) {
            my $piece = $torrent{refaddr $self}
                ->_piece_by_index($request->{q[Index]});
            delete $piece->{q[Blocks_Requested]}->[$request->{q[_vec_offset]}]
                ->{refaddr $self};
        }
        return $requests_out{refaddr $self} = [];
    }

    sub __handle_unchoke {

        # warn((caller(0))[3]);
        my ($self) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        ${$peer_choking{refaddr $self}} = 0;
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => UNCHOKE
                                        }
        );
        $self->_request_block(2);
        return 1;
    }

    sub __handle_interested {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        ${$peer_interested{refaddr $self}} = 1;
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => INTERESTED
                                        }
        );
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        $self->_send_unchoke();
        return 1;
    }

    sub __handle_not_interested {

        # warn((caller(0))[3]);
        my ($self) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => NOT_INTERESTED
                                        }
        );
        ${$peer_interested{refaddr $self}} = 1;
        ${$am_choking{refaddr $self}}      = 1;
        return 1;
    }

    sub __handle_have {

        # warn((caller(0))[3]);
        my ($self, $index) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if !defined $index;
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {Index => $index},
                                         Type    => HAVE
                                        }
        );
        vec(${$bitfield{refaddr $self}}, $index, 1) = 1;
        if ((unpack(q[b*], ${$bitfield{refaddr $self}}) !~ m[1])
            && $torrent{refaddr $self}->is_complete)
        {   weaken $self;
            $self->_disconnect(DISCONNECT_SEED);
            return;
        }
        $self->_check_interest;
        if (${$am_interested{refaddr $self}}
            and not ${$peer_choking{refaddr $self}})
        {   $self->_request_block;
        }
    }

    sub __handle_bitfield {

        # warn((caller(0))[3]);
        my ($self, $payload) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if !defined $payload;
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        ${$bitfield{refaddr $self}} = $payload;
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {Bitfield => $payload},
                                         Type    => BITFIELD
                                        }
        );
        if ((unpack(q[b*], ${$bitfield{refaddr $self}}) !~ m[1])
            && $torrent{refaddr $self}->is_complete)
        {   weaken $self;
            $self->_disconnect(DISCONNECT_SEED);
            return;
        }
        return $self->_check_interest;
    }

    sub __handle_request {

        # warn((caller(0))[3]);
        my ($self, $payload) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if !defined $payload;
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {Index  => $payload->[0],
                                                     Offset => $payload->[1],
                                                     Length => $payload->[2]
                                         },
                                         Type => REQUEST
                                        }
        );
        if (not @{$requests_in{refaddr $self}}) {
            $_client{refaddr $self}->_schedule({Time   => time + 3,
                                                Code   => \&_fill_requests,
                                                Object => $self
                                               }
            );
        }
        return push @{$requests_in{refaddr $self}},
            {Index  => $payload->[0],
             Offset => $payload->[1],
             Length => $payload->[2]
            };
    }

    sub __handle_piece {

        # warn((caller(0))[3]);
        my ($self, $payload) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $payload;
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        my ($index, $offset, $data) = @{$payload};
        my $length = length($data);
        my ($request) = grep {
                    ($_->{q[Index]} == $index)
                and ($_->{q[Offset]} == $offset)
                and ($_->{q[Length]} == $length)
        } @{$requests_out{refaddr $self}};
        if (not defined $request) {
            weaken $self;
            $self->_disconnect(-26);
            return;
        }
        $torrent{refaddr $self}->_add_downloaded($request->{q[Length]});
        @{$requests_out{refaddr $self}} = grep {
                   ($_->{q[Index]} != $index)
                or ($_->{q[Offset]} != $offset)
                or ($_->{q[Length]} != $length)
        } @{$requests_out{refaddr $self}};
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Payload => {Index  => $index,
                                                     Offset => $offset,
                                                     Length => $length
                                         },
                                         Peer => $self,
                                         Type => PIECE
                                        }
        );
        my $piece = $torrent{refaddr $self}->_piece_by_index($index);
        my $okay  = 0;
        for my $_retry (1 .. 3) {

            if ($torrent{refaddr $self}->_write_data($index, $offset, \$data))
            {   $okay++;
                last;
            }
        }
        return if !$okay;
        $piece->{q[Blocks_Received]}->[$request->{q[_vec_offset]}] = 1;
        $piece->{q[Slow]}                                          = 0;
        $piece->{q[Touch]}                                         = time;
        for my $peer ($torrent{refaddr $self}->peers) {
            for my $x (reverse 0 .. $#{$requests_out{refaddr $peer}}) {
                if (    (defined $requests_out{refaddr $peer}->[$x])
                    and
                    ($requests_out{refaddr $peer}->[$x]->{q[Index]} == $index)
                    and ($requests_out{refaddr $peer}->[$x]->{q[Offset]}
                         == $offset)
                    and ($requests_out{refaddr $peer}->[$x]->{q[Length]}
                         == $length)
                    )
                {   $_data_out{refaddr $peer } .=
                        build_cancel($request->{q[Index]},
                                     $request->{q[Offset]},
                                     $request->{q[Length]}
                        );
                    $_client{refaddr $self}->_event(q[outgoing_packet],
                                                    {Payload => {
                                                            Index  => $index,
                                                            Offset => $offset,
                                                            Length => $length
                                                     },
                                                     Peer => $peer,
                                                     Type => CANCEL
                                                    }
                    );
                    $_client{refaddr $self}->_add_connection($peer, q[rw]);
                    splice(@{$requests_out{refaddr $peer }}, $x, 1);
                    last;
                }
            }
        }
        if (not grep { !$_ } @{$piece->{q[Blocks_Received]}}) {
            if ($torrent{refaddr $self}->_check_piece_by_index($index)
                and defined $torrent{refaddr $self})
            {   for my $p ($torrent{refaddr $self}->peers) {
                    $_data_out{refaddr $p} .= build_have($index);
                    $_client{refaddr $self}->_add_connection($p, q[rw]);
                }
            }
        }
        $self->_request_block if $self->_check_interest;
        return 1;
    }

    sub __handle_cancel {

        # warn((caller(0))[3]);
        my ($self, $payload) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if !defined $payload;
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        my ($index, $offset, $length) = @$payload;
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Payload => {Index  => $index,
                                                     Offset => $offset,
                                                     Length => $length
                                         },
                                         Peer => $self,
                                         Type => CANCEL
                                        }
        );
        for my $x (reverse 0 .. $#{$requests_in{refaddr $self}}) {
            if (    ($requests_in{refaddr $self}->[$x]->{q[Index]} == $index)
                and
                ($requests_in{refaddr $self}->[$x]->{q[Offset]} == $offset)
                and
                ($requests_in{refaddr $self}->[$x]->{q[Length]} == $length))
            {   splice(@{$requests_in{refaddr $self}}, $x, 1);
            }
        }
        return 1;
    }

    sub __handle_have_all {

        # warn((caller(0))[3]);
        my ($self) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (!$torrent{refaddr $self}->status & 1) {
            weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        ${$bitfield{refaddr $self}}
            = pack(q[b*], qq[\1] x $torrent{refaddr $self}->piece_count);
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => HAVE_ALL
                                        }
        );
        if ($torrent{refaddr $self}->is_complete) {
            weaken $self;
            $self->_disconnect(DISCONNECT_SEED);
            return;
        }
        $self->_check_interest;
        if (${$am_interested{refaddr $self}}
            and not ${$peer_choking{refaddr $self}})
        {   $self->_request_block;
        }
        return 1;
    }

    sub __handle_have_none {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (!($torrent{refaddr $self}->status & 1)) {
            weaken $self;    # this should never happen
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT);
            return;
        }
        ${$bitfield{refaddr $self}}
            = pack(q[b*], qq[\0] x $torrent{refaddr $self}->piece_count);
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => HAVE_NONE
                                        }
        );
        return $self->_check_interest;
    }

    sub __handle_allowed_fast {

        # warn((caller(0))[3]);
        my ($self, $payload) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if !defined $payload;
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Payload => {Index => $payload},
                                         Peer    => $self,
                                         Type    => ALLOWED_FAST
                                        }
        );
        push(@{$_incoming_fastset{refaddr $self}}, $payload);
        return 1;
    }

    sub __handle_reject {

        # warn((caller(0))[3]);
        my ($self, $payload) = @_;
        $_client{refaddr $self}->_add_connection($self, q[rw]);
        return if !defined $payload;
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        my ($index, $offset, $length) = @{$payload};
        my ($request) = grep {
                    ($_->{q[Index]} == $index)
                and ($_->{q[Offset]} == $offset)
                and ($_->{q[Length]} == $length)
        } @{$requests_out{refaddr $self}};

        if (not defined $request) {
            weaken $self;
            $self->_disconnect(-29);
            return;
        }
        @{$requests_out{refaddr $self}} = grep {
                   ($_->{q[Index]} != $index)
                or ($_->{q[Offset]} != $offset)
                or ($_->{q[Length]} != $length)
        } @{$requests_out{refaddr $self}};
        my $piece = $torrent{refaddr $self}->_piece_by_index($index);
        if (not defined $piece) {
            weaken $self;
            $self->_disconnect(-28);
            return;
        }
        delete $piece->{q[Blocks_Requested]}->[$request->{q[_vec_offset]}]
            ->{refaddr $self};
        $_client{refaddr $self}->_event(q[incoming_packet],
                                        {Payload => {Index  => $index,
                                                     Offset => $offset,
                                                     Length => $length
                                         },
                                         Peer => $self,
                                         Type => REJECT
                                        }
        );
        return 1;
    }

    sub __handle_ext_protocol {

        # warn((caller(0))[3]);
        my ($self, $payload) = @_;
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if !defined $payload;
        if (defined $torrent{refaddr $self}    # this should never happen
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT);
            return;
        }
        return if $torrent{refaddr $self}->status & 32;
        my ($id, $packet) = @{$payload};
        if ($packet) {
            if ($id == 0) {
                if (    defined $_client{refaddr $self}->_dht
                    and defined $packet->{q[p]})
                {   my (undef, $packed_ip)
                        = unpack_sockaddr_in(
                                        getpeername($_socket{refaddr $self}));
                    $_client{refaddr $self}->_dht->add_node(
                                              {ip   => inet_ntoa($packed_ip),
                                               port => $packet->{q[p]}
                                              }
                    );
                }
            }
            $packet->{q[ID]} = $id;
            $_client{refaddr $self}->_event(q[incoming_packet],
                                            {Payload => $packet,
                                             Peer    => $self,
                                             Type    => EXTPROTOCOL
                                            }
            );
        }
        return 1;
    }

    sub _check_interest {

        # warn((caller(0))[3]);
        my ($self) = @_;
        if (!$torrent{refaddr $self}) { return; }
        if (!($torrent{refaddr $self}->status & 1)) {
            weaken $self;    # this should never happen
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT);
            return;
        }
        return if $torrent{refaddr $self}->status & 32;
        my $interesting  = ${$am_interested{refaddr $self}};
        my $torrent_have = $torrent{refaddr $self}->bitfield();
        my $torrent_want = $torrent{refaddr $self}->_wanted();
        my $relevence    = ${$bitfield{refaddr $self}} & $torrent_want;
        $interesting = (index(unpack(q[b*], $relevence), 1, 0) != -1) ? 1 : 0;
        if ($interesting and not ${$am_interested{refaddr $self}}) {
            ${$am_interested{refaddr $self}} = 1;
            $self->_syswrite(build_interested);
            $_client{refaddr $self}->_event(q[outgoing_packet],
                          {Peer => $self, Payload => {}, Type => INTERESTED});
            $_client{refaddr $self}->_add_connection($self, q[rw]);
        }
        elsif (not $interesting and ${$am_interested{refaddr $self}}) {
            ${$am_interested{refaddr $self}} = 0;
            $self->_syswrite(build_not_interested);
            $_client{refaddr $self}->_event(q[outgoing_packet],
                      {Peer => $self, Payload => {}, Type => NOT_INTERESTED});
            $_client{refaddr $self}->_add_connection($self, q[rw]);
        }
        return ${$am_interested{refaddr $self}};
    }

    sub _disconnect_useless_peer {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if not defined $self;
        if ($_last_contact{refaddr $self} < (time - 180)) {
            weaken $self;
            $self->_disconnect(-40);
            return;
        }
        if (    ${$peer_choking{refaddr $self}}
            and ${$am_interested{refaddr $self}})
        {    # XXX - send uninterested?
            $self->_check_interest;
        }
        if (    (${$peer_choking{refaddr $self}})
            and (!${$am_interested{refaddr $self}})
            and (!${$peer_interested{refaddr $self}}))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_USELESS_PEER);
            return;
        }
        $_client{refaddr $self}->_schedule(
                            {Time   => (180 + $_last_contact{refaddr $self}),
                             Code   => \&_disconnect_useless_peer,
                             Object => $self
                            }
        );
        return 1;
    }

    sub _cancel_old_requests {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if not defined $self;
        return if not defined $_socket{refaddr $self};
        $_client{refaddr $self}->_schedule({Time   => time + 15,
                                            Code   => \&_cancel_old_requests,
                                            Object => $self
                                           }
        );
        my $canceled = 0;
        if (@{$requests_out{refaddr $self}} == []) {
            return;
        }
        for my $i (reverse(0 .. $#{$requests_out{refaddr $self}})) {
            my $request = $requests_out{refaddr $self}->[$i];
            if (time <= ($request->{q[Timestamp]} + 60)) {
                next;
            }
            my $piece = $torrent{refaddr $self}
                ->_piece_by_index($request->{q[Index]});
            delete $piece->{q[Blocks_Requested]}->[$request->{q[_vec_offset]}]
                ->{refaddr $self};
            if (!$piece->{q[Touch]} || $piece->{q[Touch]} <= time - 180) {
                $piece->{q[Slow]} = 1;
            }
            $self->_syswrite(build_cancel(
                                  $request->{q[Index]}, $request->{q[Offset]},
                                  $request->{q[Length]}
                             )
            );
            $_client{refaddr $self}->_event(
                                         q[outgoing_packet],
                                         {Payload => {
                                              Index  => $request->{q[Index]},
                                              Offset => $request->{q[Offset]},
                                              Length => $request->{q[Length]}
                                          },
                                          Peer => $self,
                                          Type => CANCEL
                                         }
            );
            splice(@{$requests_out{refaddr $self}}, $i, 1);
            $canceled++;
        }
        $_client{refaddr $self}->_add_connection($self, q[rw])
            if $canceled;
        return $canceled;
    }

    sub _request_block {

        # warn((caller(0))[3]);
        my ($self, $_range) = @_;
        return if not defined $_socket{refaddr $self};
        return if ${$peer_choking{refaddr $self}};
        if (!($torrent{refaddr $self}->status & 1)) {
            weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        return if $torrent{refaddr $self}->status & 32;
        my $return = 0;
        my $range
            = defined $_range
            ? [1 .. $_range]
            : [max(1, scalar(@{$requests_out{refaddr $self}})) .. max(
                                    25,
                                    int((2**21)
                                        / $torrent{refaddr $self}->raw_data(1)
                                            ->{q[info]}{q[piece length]}
                                    )
               )
            ];
    REQUEST:
        for (@$range) {
            my $piece = $torrent{refaddr $self}->_pick_piece($self);
            if ($piece) {
                my $vec_offset;
                if ($piece->{q[Endgame]}) {

           # This next bit selects the least requested block (max 5 requests),
           # makes sure this peer isn't already sitting on this request
           # and... I just lost my train of thought; It's Friday afternoon.
           # Regardless of how it looks, it does what I mean.
                    my $tmp_index = -1;
                    my %temp      = map {
                        $tmp_index++;
                        (        ($_ < 5)
                             and
                             ($piece->{q[Blocks_Received]}->[$tmp_index] == 0)
                            )
                            ? ($tmp_index => $_)
                            : ()
                    } @{$piece->{q[Blocks_Received]}};
                INDEX:
                    for my $index (sort { $temp{$a} <=> $temp{$b} }
                                   sort { $a <=> $b } keys %temp)
                    {
                        if (not grep {
                                (defined $piece->{q[Blocks_Requested]}
                                     ->[$index]->{refaddr $self})
                                    and (
                                    ($piece->{q[Blocks_Received]}->[$index])
                                    or (($piece->{q[Index]} == $_->{q[Index]})
                                        and ($index == $_->{q[_vec_offset]}))
                                    )
                            } @{$requests_out{refaddr $self}}
                            )
                        {   $vec_offset = $index;
                            last INDEX;
                        }
                    }
                }
                else {
                BLOCK:
                    for my $i (0 .. $#{$piece->{q[Blocks_Requested]}}) {
                        if (not(keys %{$piece->{q[Blocks_Requested]}->[$i]}))
                        {   $vec_offset = $i;
                            last BLOCK;
                        }
                    }
                }
                if (not defined $vec_offset or $vec_offset == -1) {

                    # xxx - pick a different piece?
                    # xxx - Honestly, this piece shouldn't have been returned
                    #       from _pick_piece in the first place...
                    last REQUEST;
                }
                $piece->{q[Blocks_Requested]}->[$vec_offset]->{refaddr $self}
                    = $self;
                weaken $piece->{q[Blocks_Requested]}->[$vec_offset]
                    ->{refaddr $self};
                my $offset = $vec_offset * $piece->{q[Block_Length]};
                my $length = (
                          (($vec_offset + 1) == $piece->{q[Block_Count]})
                          ? (($piece->{q[Length]} % $piece->{q[Block_Length]})
                             || $piece->{q[Block_Length]})
                          : ($piece->{q[Block_Length]})
                );
                my $request = {Index       => $piece->{q[Index]},
                               Offset      => $offset,
                               Length      => $length,
                               Timestamp   => time,
                               _vec_offset => $vec_offset,
                };
                push @{$requests_out{refaddr $self}}, $request;
                $_client{refaddr $self}->_event(
                                             q[outgoing_packet],
                                             {Payload => {
                                                  Index => $piece->{q[Index]},
                                                  Offset => $offset,
                                                  Length => $length
                                              },
                                              Peer => $self,
                                              Type => REQUEST
                                             }
                );
                $_client{refaddr $self}->_add_connection($self, q[rw]);
                $self->_syswrite(
                         build_request($piece->{q[Index]}, $offset, $length));
                $return++;
            }
            else {
                last REQUEST;
            }
        }
        return $return;
    }

    sub _send_bitfield {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $torrent{refaddr $self};
        return $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
            if !$torrent{refaddr $self}->status & 1;
        return if !defined $_socket{refaddr $self};
        return if !defined $reserved_bytes{refaddr $self};
        my ($_i, @have) = (0);
        for my $x (split q[], unpack q[b*], $torrent{refaddr $self}->bitfield)
        {   push @have, $_i if $x;
            $_i++;
        }
        if (   (scalar(@have) == 0)
            && (ord(substr($reserved_bytes{refaddr $self}, 7, 1)) & 0x04))
        {   $self->_syswrite(build_have_none);
            $_client{refaddr $self}->_event(q[outgoing_packet],
                           {Peer => $self, Payload => {}, Type => HAVE_NONE});
        }
        elsif (   (scalar(@have) == $self->torrent->piece_count)
               && (ord(substr($reserved_bytes{refaddr $self}, 7, 1)) & 0x04))
        {   $self->_syswrite(build_have_all);
            $_client{refaddr $self}->_event(q[outgoing_packet],
                            {Peer => $self, Payload => {}, Type => HAVE_ALL});
        }
        elsif (scalar(@have) > 12) {
            $self->_syswrite(build_bitfield(pack q[B*], unpack q[b*],
                                            $torrent{refaddr $self}->bitfield
                             )
            );
            $_client{refaddr $self}->_event(q[outgoing_packet],
                            {Peer => $self, Payload => {}, Type => BITFIELD});
        }
        else {
            for my $index (@have) {
                $self->_syswrite(build_have($index));
                $_client{refaddr $self}->_event(q[outgoing_packet],
                                                {Peer    => $self,
                                                 Payload => {Index => $index},
                                                 Type    => HAVE
                                                }
                );
            }
        }
        return 1;
    }

    sub _send_extended_handshake {

        # warn((caller(0))[3]);
        my ($self) = @_;
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if not defined $reserved_bytes{refaddr $self};
        return
            if not ord(substr($reserved_bytes{refaddr $self}, 5, 1)) & 0x10;
        my ($_peerport, $_packed_ip)
            = unpack_sockaddr_in(getpeername($_socket{refaddr $self}));
        my $_id      = 0;
        my $_payload = {

            #m => {$_private{refaddr $self} ? () : (ut_pex => 1)}, # TODO: PEX
            ($_client{refaddr $self}->_use_dht
             ? (p => $_client{refaddr $self}->_udp_port)
             : ()
            ),
            v => $Net::BitTorrent::Version::PRODUCT_TOKEN,
            ($_packed_ip ? (yourip => $_packed_ip) : ()),
            reqq => 30    # XXX - Lies
        };
        $_client{refaddr $self}->_event(q[outgoing_packet],
                                        {Payload => $_payload,
                                         ID      => $_id,
                                         Peer    => $self,
                                         Type    => EXTPROTOCOL
                                        }
        );
        return $self->_syswrite(build_extended($_id, $_payload));
    }

    sub _send_keepalive {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if not defined $self;
        return if not defined $_socket{refaddr $self};
        return if not defined $torrent{refaddr $self};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        $_client{refaddr $self}->_schedule({Time   => time + 120,
                                            Code   => \&_send_keepalive,
                                            Object => $self
                                           }
        );
        return if $torrent{refaddr $self}->status & 32;
        $_client{refaddr $self}->_event(q[outgoing_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => KEEPALIVE
                                        }
        );
        $self->_syswrite(build_keepalive);
        $self->_check_interest;
        return 1;
    }

    sub _fill_requests {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        return if $torrent{refaddr $self}->status & 32;
        return if not @{$requests_in{refaddr $self}};
        return if ${$am_choking{refaddr $self}};
        if (defined $torrent{refaddr $self}
            and !($torrent{refaddr $self}->status & 1))
        {   weaken $self;
            $self->_disconnect(DISCONNECT_NO_SUCH_TORRENT)
                ;    # this should never happen
            return;
        }
        if (defined $torrent{refaddr $self}
            and ($torrent{refaddr $self}->status & 32))
        {   return;
        }
        while ((length($_data_out{refaddr $self}) < 2**18)
               and @{$requests_in{refaddr $self}})
        {   my $request = shift @{$requests_in{refaddr $self}};
            next
                unless $torrent{refaddr $self}
                    ->_check_piece_by_index($request->{q[Index]});
            next unless $request->{q[Length]};
            $torrent{refaddr $self}->_add_uploaded($request->{q[Length]});
            $_client{refaddr $self}->_event(
                                         q[outgoing_packet],
                                         {Payload => {
                                              Index  => $request->{q[Index]},
                                              Offset => $request->{q[Offset]},
                                              Length => $request->{q[Length]}
                                          },
                                          Peer => $self,
                                          Type => PIECE
                                         }
            );
            $self->_syswrite(
                          build_piece(
                              $request->{q[Index]},
                              $request->{q[Offset]},
                              $torrent{refaddr $self}->_read_data(
                                  $request->{q[Index]}, $request->{q[Offset]},
                                  $request->{q[Length]}
                              )
                          )
            );

            #if (rand(20) >= 20) { $self->_send_choke; }
        }
        $_client{refaddr $self}->_schedule({Time   => time + 3,
                                            Code   => \&_fill_requests,
                                            Object => $self
                                           }
        ) if @{$requests_in{refaddr $self}};
        $_client{refaddr $self}->_add_connection($self, q[rw]) or return;
        return 1;
    }

    sub _send_choke {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (defined $torrent{refaddr $self}
            and $torrent{refaddr $self}->status & 2)
        {   weaken $self;
            $self->_disconnect(DISCONNECT_HASHCHECKING);
            return;
        }
        return if ${$am_choking{refaddr $self}} == 1;
        $requests_in{refaddr $self} = [];
        ${$am_choking{refaddr $self}}      = 1;
        ${$peer_interested{refaddr $self}} = 0;
        $self->_syswrite(build_choke);
        $_client{refaddr $self}->_event(q[outgoing_packet],
                                        {Peer    => $self,
                                         Payload => {},
                                         Type    => CHOKE
                                        }
        );
        $_client{refaddr $self}->_add_connection($self, q[rw]) or return;
        return 1;
    }

    sub _send_unchoke {

        # warn((caller(0))[3]);
        my ($self) = @_;
        return if !defined $torrent{refaddr $self};
        return if !defined $_socket{refaddr $self};
        if (defined $torrent{refaddr $self}
            and $torrent{refaddr $self}->status & 2)
        {   weaken $self;
            $self->_disconnect(DISCONNECT_HASHCHECKING);
            return;
        }
        return if $torrent{refaddr $self}->status & 32;
        return if ${$am_choking{refaddr $self}} == 0;
        if (scalar(grep { $_->am_choking == 0 } $torrent{refaddr $self}->peers
            ) <= 16    # XXX - client wide limit on number of unchoked peers
            )
        {   ${$am_choking{refaddr $self}} = 0;
            $self->_syswrite(build_unchoke);
            $_client{refaddr $self}->_event(q[outgoing_packet],
                             {Peer => $self, Payload => {}, Type => UNCHOKE});
            $_client{refaddr $self}->_add_connection($self, q[rw])
                or return;
        }
        else {
            $_client{refaddr $self}->_schedule({Time   => time + 15,
                                                Code   => \&_send_unchoke,
                                                Object => $self
                                               }
            );
        }
        return 1;
    }

    sub _disconnect {

# warn((caller(0))[3]);
# Returns...
#        1) ...when the socket is disconnected and (if applicable)
#             removed from the client object.
#    undef) ...whe any of the following cause an early return or
#             the socket cannot be removed from the parent.
# Expects the following parameters:
#  - a reference to a blessed N::B::S::Peer (the only required parameter)
#  - a numeric 'reason' (defaults to 0, positive are winsock, negative are user)
#  - extra data in a hash ref (passed on to peer_disconnect callback in 'Advanced' key)
        my ($self, $reason, $extra) = @_;
        $_client{refaddr $self}->_remove_connection($self);
        if (defined $_socket{refaddr $self}) {
            shutdown($_socket{refaddr $self}, 2);
            close($_socket{refaddr $self});
        }
        delete $_socket{refaddr $self};
        $_client{refaddr $self}->_event(q[peer_disconnect],
                                        {Peer   => $self,
                                         Reason => ($reason + 0),
                                         ($extra ? (Advanced => $extra) : ())
                                        }
        );
        return 1;
    }

    sub as_string {

        # warn((caller(0))[3]);
        my ($self, $advanced) = @_;
        my $dump = sprintf(
            (!$advanced ? q[%s:%s (%s)] : <<'ADVANCED'),
Net::BitTorrent::Peer

Address:     %s:%s
Peer ID:     %s
Torrent:     %s
Direction:   %s

Interested:  %s
Interesting: %s
Choked:      %s
Choking:     %s

Progress:
[%s]
ADVANCED
            ($self->host || q[]),
            ($self->port || q[]),
            ($peerid{refaddr $self} ? $peerid{refaddr $self} : q[Unknown]),
            (  $torrent{refaddr $self}
             ? $torrent{refaddr $self}->infohash
             : q[Unknown]
            ),
            ($incoming{refaddr $self} ? q[Incoming] : q[Outgoing]),
            (map { $_ ? q[Yes] : q[No] } (${$peer_interested{refaddr $self}},
                                          ${$am_interested{refaddr $self}},
                                          ${$am_choking{refaddr $self}},
                                          ${$peer_choking{refaddr $self}}
             )
            ),
            (($_state{refaddr $self} == REG_OKAY)
             ? (sprintf q[%s],
                join q[],
                map { vec(${$bitfield{refaddr $self}}, $_, 1) ? q[|] : q[ ] }
                    0 .. $torrent{refaddr $self}->piece_count - 1
                 )
             : q[NA]
            )
        );
        return defined wantarray ? $dump : print STDERR qq[$dump\n];
    }

    sub CLONE {
        ## warn((caller(0))[3]);
        for my $_oID (keys %REGISTRY) {
            my $_obj = $REGISTRY{$_oID};
            my $_nID = refaddr $_obj;
            for (@CONTENTS) {
                $_->{$_nID} = $_->{$_oID};
                delete $_->{$_oID};
            }
            weaken $_client{$_nID};
            weaken $torrent{$_nID};
            weaken($REGISTRY{$_nID} = $_obj);
            delete $REGISTRY{$_oID};
        }
        return 1;
    }
    DESTROY {
        my ($self) = @_;
        if ($torrent{refaddr $self}) {
            for my $request (@{$requests_out{refaddr $self}}) {
                my $piece = $torrent{refaddr $self}
                    ->_piece_by_index($request->{q[Index]});
                delete $piece->{q[Blocks_Requested]}
                    ->[$request->{q[_vec_offset]}]->{refaddr $self};
            }
        }
        for (@CONTENTS) { delete $_->{refaddr $self}; }
        return delete $REGISTRY{refaddr $self};
    }

    sub _RC4 {
        ## warn((caller(0))[3]);
        my ($self, $pass, $text, $reset) = @_;
        my $rc4_output = sub {    # PRGA
            $_i{refaddr $self}{$pass} = ($_i{refaddr $self}{$pass} + 1) & 255;
            $_j{refaddr $self}{$pass}
                = (  $_j{refaddr $self}{$pass}
                   + $_RC4_S{refaddr $self}{$pass}[$_i{refaddr $self}{$pass}]
                ) & 255;
            @{$_RC4_S{refaddr $self}{$pass}}[$_i{refaddr $self}{$pass},
                $_j{refaddr $self}{$pass}]
                = @{$_RC4_S{refaddr $self}{$pass}}[$_j{refaddr $self}{$pass},
                $_i{refaddr $self}{$pass}];
            return
                $_RC4_S{refaddr $self}{$pass}[
                (     $_RC4_S{refaddr $self}{$pass}[$_i{refaddr $self}{$pass}]
                    + $_RC4_S{refaddr $self}{$pass}
                    [$_j{refaddr $self}{$pass}]) & 255
                ];
        };
        my $_j = 0;
        if ($reset || !$_RC4_S{refaddr $self}{$pass}) {
            my @key = unpack q[C*], $pass;
            @{$_RC4_S{refaddr $self}{$pass}} = 0 .. 255;    # KSA
            ($_i{refaddr $self}{$pass}, $_j{refaddr $self}{$pass}) = (0, 0);
            for my $_i (0 .. 255) {
                $_j
                    = (  $_j 
                       + $key[$_i % @key]
                       + $_RC4_S{refaddr $self}{$pass}[$_i]) & 255;
                @{$_RC4_S{refaddr $self}{$pass}}[$_i, $_j]
                    = @{$_RC4_S{refaddr $self}{$pass}}[$_j, $_i];
            }
        }
        return pack q[C*],
            map { ord(substr($text, $_, 1)) ^ $rc4_output->() }
            0 .. length($text) - 1;
    }
    1;
}

=pod

=head1 NAME

Net::BitTorrent::Peer - Remote BitTorrent Peer

=head1 Description

L<Net::BitTorrent::Peer|Net::BitTorrent::Peer> represents a single peer
connection.

=head1 Constructor

=over

=item C<new ( { [ARGS] } )>

Creates a L<Net::BitTorrent::Peer|Net::BitTorrent::Peer> object.  This
constructor should not be used directly.

=back

=head1 Methods

=over

=item C<bitfield ( )>

Returns a bitfield representing the pieces that have been reported to be
successfully downloaded by the remote peer.

=item C<am_choking ( )>

Returns a boolean value based on whether or not we are currently choking
the remote peer.

=item C<am_interested ( )>

Returns a boolean value based on whether or not we are currently
interested in the set of pieces held by the remote peer

=item C<host ( )>

Returns the host (typically an IP address) of the remote peer.

=item C<incoming ( )>

Returns a boolean value based on whether or not this connection was
initiated by the remote peer or us.

=item C<peer_choking ( )>

Returns a boolean value based on whether or not the remote peer is
currently choking us.

=item C<peer_interested ( )>

Returns a boolean value based on whether or not the remote peer is
currently interested in being unchoked or in requesting data from us.

=item C<peerid ( )>

Returns the Peer ID used to identify this peer.

See also: theory.org (http://tinyurl.com/4a9cuv)

=item C<port ( )>

The port used by the remote peer.

=item C<reserved_bytes ( )>

Returns the C<8> reserved bytes from the plaintext handshake. Each bit in
these bytes can be used to change the behavior of the protocol.

See also: theory.org (http://tinyurl.com/aw76zb)

=item C<source ( )>

In a future version, this will return how we obtained this connection
(DHT, user, incoming, certain tracker, etc.).

=item C<torrent ( )>

Returns the related L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent>
object. This will be C<undef> if the peer has not completed the
handshake.

=item C<as_string ( [ VERBOSE ] )>

Returns a 'ready to print' dump of the  object's data structure.  If
called in void context, the structure is printed to C<STDERR>.
C<VERBOSE> is a boolean value.

=back

=begin :podcoverage

=over

=item CRYPTO_AES

=item CRYPTO_PLAIN

=item CRYPTO_RC4

=item CRYPTO_XOR

=item DH_G

=item DH_P

=item MSE_FIVE

=item MSE_FOUR

=item MSE_ONE

=item MSE_THREE

=item MSE_TWO

=item REG_OKAY

=item REG_ONE

=item REG_THREE

=item REG_TWO

=item VC

=item crypto_provide

=item len

=back

=end :podcoverage

=head1 Notes

As of version C<0.049_8> of this module, C<peer_disconnect> callbacks are
provided with a language agnostic, numeric reason. So far, this is the
list of possible disconnections:

=over

=item DISCONNECT_BY_REMOTE

The connection closed by remote peer for unknown reasons

=item DISCONNECT_LOOPBACK

We connected to ourself according to PeerID.

=item DISCONNECT_NO_SUCH_TORRENT

Remote peer attempted to create a session related to a torrent we aren't
currently serving. Occasionally, this will also provide an C<Infohash>
parameter for your callback.

=item DISCONNECT_HANDSHAKE_INFOHASH

A remote peer sent us a bad plaintext handshake. This is triggered when,
after a particular infohash was implied in an encrypted handshake, the
remote peer sent us a mismatched infohash in the plaintext handshake.

=item DISCONNECT_MALFORMED_HANDSHAKE

Bad plaintext handshake. May be malformed or, if encryption is disabled
locally, the remote peer attempted an encrypted handshake.

=item DISCONNECT_MALFORMED_PACKET

This is given when the remote peer gives us a malformed packet. See also
L<DISCONNECT_MALFORMED_HANDSHAKE|/"DISCONNECT_MALFORMED_HANDSHAKE">.

=item DISCONNECT_PREXISTING

Already connected to this peer. When there are too many established
connections with a particular peer (as determined by their PeerID), we
disconnect further connections with the reason. This reason provides
the remote peer's C<PeerID> when triggered.

=item DISCONNECT_TOO_MANY

Enough peers already! We've hit the hard limit for the number of peers
allowed globally or per torrent.

=item DISCONNECT_HASHCHECKING

This reason is given when a remote peer connects to us while the torrent
they're seeking is busy being hash checked (potentially in another
thread).

=item DISCONNECT_SEED

This is given when we and the remote peer are both seeds.

=item DISCONNECT_TIMEOUT_HANDSHAKE

Peer failed to complete plaintext or encrypted handshake within 30s.

=item DISCONNECT_USELESS_PEER

Peer has been connected for at least 3m and is neither interested nor
interesting.

=item DISCONNECT_HANDSHAKE_SYNC_DH5

Failed to sync MSE handshake at stage five.

=begin TODO

        -26 => q[Handed a piece we never asked for]
        ,    # { Index => \d, Offset => \d, Length=> \d }
        -28 => q[Sent a reject to a non-existant piece],
        -29 => q[Rejected a request we never made.],
        -40 => q[Peer is idle],
        -101 => q[Bad VC in encrypted handshake],
        -103 => q[Bad encrypted header at stage 4],
        -104 => q[Bad encrypted handshake (Bad SKEY)],
        -105 => q[Unsupported encryption scheme]

=end TODO

=back

To import this list of keywords into your namespace, use the C<disconnect>
tag. Please note that this API tweak is experimental and may change or be
removed in a future version. ...it's also probably incomplete.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.  See the F<LICENSE>
file included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

Neither this module nor the L<Author|/Author> is affiliated with
BitTorrent, Inc.

=for svn $Id: Peer.pm 07f0c35 2010-04-02 18:31:29Z sanko@cpan.org $

=cut
