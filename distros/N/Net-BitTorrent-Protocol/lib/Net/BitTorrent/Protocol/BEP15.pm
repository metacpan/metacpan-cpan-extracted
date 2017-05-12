package Net::BitTorrent::Protocol::BEP15;
our $VERSION = "1.5.3";
use strict;
use warnings;
use Type::Utils;
use Type::Params qw[compile];
use Types::Standard qw[slurpy Dict ArrayRef Optional Maybe Int Str Enum];
use Carp qw[carp];
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use Exporter qw[];
*import = *import = *Exporter::import;
%EXPORT_TAGS = (
    build => [
        qw[ build_connect_request  build_connect_reply
            build_announce_request build_announce_reply
            build_scrape_request   build_scrape_reply
            build_error_reply
            ]
    ],
    parse => [
        qw[ parse_connect_request  parse_connect_reply
            parse_announce_request parse_announce_reply
            parse_scrape_request   parse_scrape_reply
            parse_error_reply
            parse_request          parse_reply
            ]
    ],
    types => [
        qw[ $CONNECT $ANNOUNCE  $SCRAPE  $ERROR
            $NONE    $COMPLETED $STARTED $STOPPED ]
    ]
);
@EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;
use Digest::SHA qw[sha1];
use Net::BitTorrent::Protocol::BEP23 qw[compact_ipv4 uncompact_ipv4];
#
our $CONNECTION_ID = 4497486125440;    # 0x41727101980

# Actions
our $CONNECT  = 0;
our $ANNOUNCE = 1;
our $SCRAPE   = 2;
our $ERROR    = 3;

# Events
our $NONE      = 0;
our $COMPLETED = 1;
our $STARTED   = 2;
our $STOPPED   = 3;

# Build functions
sub build_connect_request {
    CORE::state $check = compile(slurpy Dict [transaction_id => Int]);
    my ($args) = $check->(@_);
    return pack 'Q>ll', $CONNECTION_ID, $CONNECT, $args->{transaction_id};
}

sub build_connect_reply {
    CORE::state $check
        = compile(slurpy Dict [transaction_id => Int, connection_id => Int]);
    my ($args) = $check->(@_);
    return pack 'llQ>', $CONNECT, $args->{transaction_id},
        $args->{connection_id};
}

sub build_announce_request {
    CORE::state $check = compile(
        slurpy Dict [
            connection_id  => Int,
            transaction_id => Int,
            info_hash      => Str,
            peer_id        => Str,
            downloaded     => Int,
            left           => Int,
            uploaded       => Int,
            event          => Enum [$NONE, $COMPLETED, $STARTED, $STOPPED],
            ip => Optional [Str],    # Default: 0
            key            => Int,
            num_want       => Optional [Int],       # Default: -1
            port           => Int,
            request_string => Optional [Str],
            authentication => Optional [ArrayRef]
        ]
    );
    my ($args) = $check->(@_);
    my $data = pack 'Q>NN a20a20 Q>Q>Q>N a4 Nl>n',
        $args->{connection_id}, $ANNOUNCE, $args->{transaction_id},
        $args->{info_hash}, $args->{peer_id},
        $args->{downloaded}, $args->{left}, $args->{uploaded}, $args->{event},
        (defined $args->{ip} ?
             $args->{ip} =~ m[\.] ?
                 (pack("C4", split(/\./, $args->{ip})))
             : pack 'N',
             0
             : pack 'N',
             0
        ),
        $args->{key}, ($args->{num_want} // -1), $args->{port};
    my $ext = 0;
    $ext ^= 1 if defined $args->{authentication};
    $ext ^= 2 if defined $args->{request_string};
    $data .= pack 'n', $ext;
    if (defined $args->{authentication}) {
        $data .= pack('ca*',
                      length($args->{authentication}[0]),
                      $args->{authentication}[0]);
        $data .= pack('a8', sha1($data, sha1($args->{authentication}[1])));
    }
    $data
        .= pack('ca*', length($args->{request_string}),
                $args->{request_string})
        if defined $args->{request_string};
    $data;
}

sub build_announce_reply {
    CORE::state $check = compile(slurpy Dict [
                                          transaction_id => Int,
                                          interval       => Int,
                                          leechers       => Int,
                                          seeders        => Int,
                                          peers => ArrayRef [Maybe [ArrayRef]]
                                 ]
    );
    my ($args) = $check->(@_);
    pack 'NNNNNa*',
        $ANNOUNCE,
        (map { $args->{$_} } qw[transaction_id interval leechers seeders]),
        (compact_ipv4(@{$args->{peers}}) // '');
}

sub build_scrape_request {
    CORE::state $check = compile(slurpy Dict [connection_id  => Int,
                                              transaction_id => Int,
                                              info_hash      => ArrayRef [Str]
                                 ]
    );
    my ($args) = $check->(@_);
    return pack 'Q>NN(a20)*',
        $args->{connection_id}, $SCRAPE, $args->{transaction_id},
        @{$args->{info_hash}};
}

sub build_scrape_reply {
    CORE::state $check = compile(
          slurpy Dict [
              transaction_id => Int,
              scrape =>
                  ArrayRef [
                  Dict [downloaded => Int, incomplete => Int, complete => Int]
                  ]
          ]
    );
    my ($args) = $check->(@_);
    CORE::state $keys = [qw[complete downloaded incomplete]];
    my $data = pack 'NN', $SCRAPE, $args->{transaction_id};
    for my $scrape (@{$args->{scrape}}) {
        for my $key (@$keys) {
            $data .= pack 'N', $scrape->{$key};
        }
    }
    $data;
}

sub build_error_reply {
    CORE::state $check = compile(slurpy Dict [transaction_id   => Int,
                                              'failure reason' => Str
                                 ]
    );
    my ($args) = $check->(@_);
    return pack 'NNa*', $ERROR,
        map { $args->{$_} } qw[transaction_id], 'failure reason';
}

# Parse functions
sub parse_connect_request {
    my ($data) = @_;
    if (length $data < 16) {
        return {fatal => 0, error => 'Not enough data'};
    }
    my ($cid, $action, $tid) = unpack 'Q>ll', $data;
    if ($cid != $CONNECTION_ID) {
        return {fatal => 1, error => 'Incorrect connection id'};
    }
    if ($action != $CONNECT) {
        return {fatal => 1,
                error => 'Incorrect action for connect request'
        };
    }
    return {transaction_id => $tid, action => $action, connection_id => $cid};
}

sub parse_connect_reply {
    my ($data) = @_;
    if (length $data < 16) {
        return {fatal => 0, error => 'Not enough data'};
    }
    my ($action, $tid, $cid) = unpack 'llQ>', $data;
    if ($action != $CONNECT) {
        return {fatal => 1,
                error => 'Incorrect action for connect request'
        };
    }
    return {transaction_id => $tid, action => $action, connection_id => $cid};
}

sub parse_announce_request {
    my ($data) = @_;
    if (length $data < 16) {
        return {fatal => 0, error => 'Not enough data'};
    }
    my ($cid, $action, $tid,
        #
        $info_hash, $peer_id,
        #
        $downloaded, $left, $uploaded, $event,
        #
        $ip,
        #
        $key, $num_want, $port, $ext, $ext_data
        )
        = unpack 'Q>NN a20a20 Q>Q>Q>N a4 Nl>nna*',
        $data;
    if ($action != $ANNOUNCE) {
        return {fatal => 1,
                error => 'Incorrect action for announce request'
        };
    }
    my $retval = {connection_id  => $cid,
                  action         => $action,
                  transaction_id => $tid,
                  info_hash      => $info_hash,
                  peer_id        => $peer_id,
                  downloaded     => $downloaded,
                  left           => $left,
                  uploaded       => $uploaded,
                  event          => $event,
                  ip             => $ip,
                  key            => $key,
                  num_want       => $num_want,
                  port           => $port,
                  ip             => (join(".", unpack("C4", $ip)))
    };
    ($retval->{authentication}[0], $retval->{authentication}[1], $ext_data)
        = unpack 'c/aa8a*', $ext_data
        if $ext & 1;
    $retval->{request_string} = unpack 'c/a', $ext_data if $ext & 2;
    $retval;
}

sub parse_announce_reply {
    my ($data) = @_;
    my ($action, $transaction_id, $interval, $leechers, $seeders, $peers)
        = unpack 'NNNNNa*', $data;
    return if $action != $ANNOUNCE;
    return {action         => $action,
            transaction_id => $transaction_id,
            interval       => $interval,
            leechers       => $leechers,
            seeders        => $seeders,
            peers          => [uncompact_ipv4 $peers]
    };
}

sub parse_scrape_request {
    my ($data) = @_;
    my ($connection_id, $action, $transaction_id, $infohash)
        = unpack 'Q>NNa*', $data;
    return if $action != $SCRAPE;
    return {action         => $action,
            connection_id  => $connection_id,
            transaction_id => $transaction_id,
            info_hash      => [unpack '(a20)*', $infohash]
    };
}

sub parse_scrape_reply {
    my ($data) = @_;
    my ($action, $transaction_id, @etc) = unpack 'NN(NNN)*', $data;
    return if $action != $SCRAPE;
    CORE::state $keys = [qw[complete downloaded incomplete]];
    my @scrape;
    while (my @next_n = splice @etc, 0, 3) {
        push @scrape, {map { $keys->[$_] => $next_n[$_] } 0 .. $#next_n};
    }
    return {action         => $action,
            transaction_id => $transaction_id,
            scrape         => [@scrape]
    };
}

sub parse_error_reply {
    my ($data) = @_;
    my ($action, $transaction_id, $failure_reason) = unpack 'NNa*', $data;
    return if $action != $ERROR;
    return {transaction_id   => $transaction_id,
            'failure reason' => $failure_reason
    };
}

sub parse_request {
    CORE::state $check = compile(Str);
    my ($data) = $check->(@_);
    my ($connection_id, $action) = unpack 'Q>N', $data;
    return parse_connect_request($data)  if $action == $CONNECT;
    return parse_announce_request($data) if $action == $ANNOUNCE;
    return parse_scrape_request($data)   if $action == $SCRAPE;
    return;
}

sub parse_reply {
    CORE::state $check = compile(Str);
    my ($data) = $check->(@_);
    my ($action) = unpack 'NN', $data;
    return parse_connect_reply($data)  if $action == $CONNECT;
    return parse_announce_reply($data) if $action == $ANNOUNCE;
    return parse_scrape_reply($data)   if $action == $SCRAPE;
    return parse_error_reply($data)    if $action == $ERROR;
    return;
}
1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP15 - Packet Utilities for BEP15, the UDP Tracker Protocol

=head1 Synopsis

    use Net::BitTorrent::Protocol::BEP15 qw[:all];

    # Tell them we want to connect...
    my $handshake = build_connect_request(255);

    # ...send to tracker and get reply...
    my ($transaction_id, $connection_id) = parse_connect_reply( $reply );

=head1 Description

What would BitTorrent be without packets? TCP noise, mostly.

For similar work and the specifications behind these packets, move on down to
the L<See Also|/"See Also"> section.

=head1 Importing from Net::BitTorrent::Protocol::BEP15

There are two tags available for import. To get them both in one go, use the
C<:all> tag.

=over

=item C<:build>

These create packets ready-to-send to trackers. See
L<Building Functions|/"Building Functions">.

=item C<:parse>

These are used to parse unknown data into sensible packets. The same packet
types we can build, we can also parse. You may want to use this to write your
own UDP tracker. See L<Parsing Functions|/"Parsing Functions">.

=back

=head2 Building Functions

=over

=item C<build_connect_request ( ... )>

Creates a request for a connection id. The provided C<transaction_id> should
be a random 32-bit integer.

=item C<build_connect_reply( ... )>

Creates a reply for a connection request. The C<transaction_id> should match
the value sent from the client. The C<connection_id> is sent with every packet
to identify the client.

=item C<build_announce_request( ... )>

Creates a packet suited to announce with the tracker. The following keys are
required:

=over

=item C<connection_id>

This is the same C<connection_id> returned by the tracker when you sent a
connection request.

=item C<transaction_id>

This is defined by you. It's a random integer which will be returned by the
tracker in response to this packet.

=item C<info_hash>

This is the packed info hash of the torrent.

=item C<peer_id>

This is your client's peer id.

=item C<downloaded>

The amount of data you have downloaded so far this session.

=item C<left>

The amount of data you have left to download before complete.

=item C<uploaded>

The amount of data you have uploaded to other peers in this session.

=item C<event>

This value is either C<$NONE>, C<$COMPLETED>, C<$STARTED>, or C<$STOPPED>.
C<$NONE> is sent when you're simply reannouncing after a certain interval.

All of these are imported with the C<:types> or C<:all> tags.

=item C<key>

A unique key that is randomized by the client. Unlike the C<transaction_id>
which is generated for every packet, this value should be kept per-session.

=item C<port>

The port you're listening on.

=back

...and the following are optional. Some have default values:

=over

=item C<request_string>

The request string extension is meant to allow torrent creators pass along
cookies back to the tracker. This can be useful for authenticating that a
torrent is allowed to be tracked by a tracker for instance. It could also be
used to authenticate users by generating torrents with unique tokens in the
tracker URL for each user.

Typically this starts with "/announce" The bittorrent client is not expected
to append query string arguments for stats reporting, like "uploaded" and
"downloaded" since this is already reported in the udp tracker protocol.
However, the client is free to add arguments as extensions.

=item C<authentication>

This is a list which contains a username and password. This function then
correctly hashes the password to sent over the wire.

=item C<ip>

Your ip address. By default, this is C<0> which tells the tracker to use the
sender of this udp packet.

=item C<num_want>

The maximum number of peers you want in the reply. The default is C<-1> which
lets the tracker decide.

=back

=item C<build_announce_reply( ... )>

Creates a packet a UDP tracker would sent in reply to an announce packet from
a client. The following are required: C<transaction_id>, the C<interval> at
which the client should reannounce, the number of C<seeders> and C<leechers>,
as well as a list of C<peers> for the given infohash.

=item C<build_scrape_request( ... )>

Creates a packet for a client to request basic data about a number of
torrents. Up to about 74 torrents can be scraped at once. A full scrape can't
be done with this protocol.

You must provide: the tracker provided C<connection_id>, a C<transaction_id>,
and a list in C<info_hash>.

=item C<build_scrape_request( ... )>

Creates a packet for a tracker to sent in reply to a scrape request. You must
provide the client defined C<transaction_id> and a list of hashes as C<scrape>
data. The hashes contain integers for the following: C<downloaded>,
C<incomplete>, and C<complete>.

=item C<build_error_reply( ... )>

Creates a packet to be sent to the client in case of an error. You must
provide a C<transaction_id> and C<failure reason>.

=back

=head2 Parsing Functions

These are the parsing counterparts for the C<build_> functions.

When the packet is invalid, a hash reference is returned with C<error> and
C<fatal> keys. The value in C<error> is a string describing what went wrong.

Return values for valid packets are explained below.

=over

=item C<parse_reply( $data )>

This will automatically call the correct parsing function for you. When you
aren't exactly sure what the data is.

=item C<parse_request( $data )>

This will automatically call the correct parsing function for you. When you
aren't exactly sure what the data is. This would be use in you're writing a
UDP tracker yourself.

=item C<parse_connect_request( $data )>

Returns the parsed transaction id.

=item C<parse_connect_reply( $data )>

Parses the reply for a connect request. Returns the original transaction id
and the new connection id.

=item C<parse_announce_request( $data )>

Returns C<connection_id>, C<transaction_id>, C<info_hash>, C<peer_id>,
C<downloaded>, C<left>, C<uploaded>, C<event>, C<ip>, C<key>, C<num_want>,
C<port>, C<ip>.

Optionally, this packet might also contian C<authentication> and
C<request_string> values.

=item C<parse_announce_reply( $data )>

Returns the C<transaction_id>, the C<interval> at which you should
re-announce, the current number of C<leechers> and C<seeders>, and an inflated
list of C<peers>.

=item C<parse_scrape_request( $data )>

Returns the C<connection_id>, C<transaction_id>, and an C<info_hash> which may
contain multiple infohashes depending on the request.

=item C<parse_scrape_reply( $data )>

Returns C<transaction_id> and list of hashes in C<scrape>. The scrape hashes
contain C<downloaded>, C<complete> and C<incomplete> keys.

=item C<parse_error_reply( $data )>

Returns C<transaction_id> and C<failure reason>.

=back

=head1 See Also

http://bittorrent.org/beps/bep_0015.html - UDP Tracker Protocol for BitTorrent

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2016 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=cut
