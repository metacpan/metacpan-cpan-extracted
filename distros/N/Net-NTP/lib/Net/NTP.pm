package Net::NTP;
use 5.008;
use strict;
use warnings;

use IO::Socket;
use constant HAVE_SOCKET_INET6 => eval { require IO::Socket::INET6 };
use Time::HiRes qw(time);

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
  get_ntp_response
);

our $VERSION = '1.5';

our $TIMEOUT = 5;

our %MODE = (
    '0' => 'reserved',
    '1' => 'symmetric active',
    '2' => 'symmetric passive',
    '3' => 'client',
    '4' => 'server',
    '5' => 'broadcast',
    '6' => 'reserved for NTP control message',
    '7' => 'reserved for private use'
);

our %STRATUM = (
    '0' => 'unspecified or unavailable',
    '1' => 'primary reference (e.g., radio clock)',
);

for (2 .. 15) {
    $STRATUM{$_} = 'secondary reference (via NTP or SNTP)';
}

for (16 .. 255) {
    $STRATUM{$_} = 'reserved';
}

our %STRATUM_ONE_TEXT = (
    'LOCL' =>
      'uncalibrated local clock used as a primary reference for a subnet without external means of synchronization',
    'PPS' =>
      'atomic clock or other pulse-per-second source individually calibrated to national standards',
    'ACTS' => 'NIST dialup modem service',
    'USNO' => 'USNO modem service',
    'PTB'  => 'PTB (Germany) modem service',
    'TDF'  => 'Allouis (France) Radio 164 kHz',
    'DCF'  => 'Mainflingen (Germany) Radio 77.5 kHz',
    'MSF'  => 'Rugby (UK) Radio 60 kHz',
    'WWV'  => 'Ft. Collins (US) Radio 2.5, 5, 10, 15, 20 MHz',
    'WWVB' => 'Boulder (US) Radio 60 kHz',
    'WWVH' => 'Kaui Hawaii (US) Radio 2.5, 5, 10, 15 MHz',
    'CHU'  => 'Ottawa (Canada) Radio 3330, 7335, 14670 kHz',
    'LORC' => 'LORAN-C radionavigation system',
    'OMEG' => 'OMEGA radionavigation system',
    'GPS'  => 'Global Positioning Service',
    'GOES' => 'Geostationary Orbit Environment Satellite',
);

our %LEAP_INDICATOR = (
    '0' => 'no warning',
    '1' => 'last minute has 61 seconds',
    '2' => 'last minute has 59 seconds)',
    '3' => 'alarm condition (clock not synchronized)'
);


use constant NTP_ADJ => 2208988800;

my @ntp_packet_fields = (
    'Leap Indicator',
    'Version Number',
    'Mode',
    'Stratum',
    'Poll Interval',
    'Precision',
    'Root Delay',
    'Root Dispersion',
    'Reference Clock Identifier',
    'Reference Timestamp',   # reftime
    'Originate Timestamp',   # T1
    'Receive Timestamp',     # T2
    'Transmit Timestamp',    # T3
    'Destination Timestamp', # T4
    'Key Identifier',
    'Message Digest',
);

## position matched description above.
my @_ntp_packet_field_names = qw/
    leap
    version
    mode
    stratum
    poll
    precision
    rootdelay
    rootdisp
    refid
    reftime
    org
    rec
    xmt
    dst
    keyid
    dgst/;

if (scalar(@_ntp_packet_field_names) != scalar(@ntp_packet_fields)) {
    die "Fatal error in packet definition, fields don't match";
}

=head2 offset($packet, $xmttime, $rectime)

Given a NTP Packet (from B), return the offset to local (A) according to its xmttime(T1) and rectime(T4)

    theta = T(B) - T(A) = 1/2 * [(T2-T1) + (T3-T4)]

=cut

sub offset {
    my $class = shift;
    my ($packet, $xmttime, $rectime) = @_;

    return ($packet->{rec} - $xmttime + $packet->{xmt} - $rectime) / 2;
}

=head2 delay($packet, $xmttime, $rectime)

Return the delay from the sender (B) of $packet given known local xmttime(T1) and rectime(T4)

    delta = T(ABA) = (T4-T1) - (T3-T2).

=cut

sub delay {
    my $class = shift;
    my ($packet, $xmttime, $rectime) = @_;
    return $rectime - $xmttime - ($packet->{xmt} - $packet->{rec});
}

sub get_ntp_response {

    my $host = shift || 'localhost';
    my $port = shift || 'ntp';

    my %args = (
        Proto    => 'udp',
        PeerHost => $host,
        PeerPort => $port
    );
    my $sock;
    if (HAVE_SOCKET_INET6) {
        $sock = IO::Socket::INET6->new(%args);
    }
    else {
        $sock = IO::Socket::INET->new(%args);
    }
    die $@ unless $sock;

    my $xmttime = time; # T1
    my $packet = Net::NTP::Packet->new_client_packet($xmttime);
    $sock->send($packet->encode)
        or die "send() failed: $!\n";

    ## receive with deadline
    my $data;
    eval {
        local $SIG{ALRM} = sub { die "Net::NTP timed out getting NTP packet\n"; };
        alarm($TIMEOUT);
        $sock->recv($data, 960)
          or die "recv() failed: $!\n";
        alarm(0);
    };
    alarm 0;

    my $rectime = time; # T4
    my $pkt = Net::NTP::Packet->decode($data, $xmttime, $rectime);

    ## Return packet hash as we used to, the pos
    my %packet = ();
    for (my $i = 0; $i < scalar @ntp_packet_fields; $i++) {
        $packet{$ntp_packet_fields[$i]} = $pkt->{$_ntp_packet_field_names[$i]};
    }

    ## some values were using a float formatter.
    $packet{"Poll Interval"} = sprintf("%.4f", $pkt->{poll});
    $packet{"Root Dispersion"} = sprintf("%.4f", $pkt->{rootdisp});

    ## some are not in the new object, but can be computed easily.
    $packet{Offset} = __PACKAGE__->offset($pkt, $xmttime, $rectime);
    $packet{Delay} = sprintf "%0.5f", __PACKAGE__->delay($pkt, $xmttime, $rectime);

    return %packet;
}


=encoding utf8

=head1 NAME

Net::NTP - Perl extension for decoding NTP server responses

=head1 SYNOPSIS

  use Net::NTP qw(get_ntp_response);
  use Time::HiRes qw(time);
  my %response = get_ntp_response();

  my $xmttime = time();
  my $spkt = Net::NTP::Packet->new_client_packet($xmttime);
  $socket->send($pkt->encode());
  $socket->recv(my $data, 1024);
  my $rectime = time();
  my $cpkt = Net::NTP::Packet->decode($data, $xmttime, $rectime);
  print "Stratum: ", $cpkt->{stratum}, "\n";
  print "Offset: ", Net::NTP->offset($pkt, $xmttime, $rectime), "\n"

=head1 ABSTRACT

All this module does is send a packet to an NTP server and then decode
the packet received into it's respective parts - as outlined in
RFC5905 (superseding RFC1305 and RFC2030).

=head1 LIMITATIONS

This only supports Association Mode 3 (Client).

=head1 DESCRIPTION

This module exports a single method (get_ntp_response) and returns an
associative array based upon RFC1305 and RFC2030.  The response from
the server is "humanized" to a point that further processing of the
information received from the server can be manipulated.  For example:
timestamps are in epoch, so one could use the localtime function to
produce an even more "human" representation of the timestamp.

=head2 EXPORT

get_ntp_response(<server>, <port>);

This module exports a single method - get_ntp_response.  It takes the
server as the first argument (localhost is the default) and port to
send/recieve the packets (ntp or 123 by default).  It returns an
associative array of the various parts of the packet as outlined in
RFC1305.  It "normalizes" or "humanizes" various parts of the packet.
For example: all the timestamps are in epoch, NOT hexidecimal.

Two special fields (C<Delay> and C<Offset>) are calculated and added to
the response.

If there's a timeout or other communications error get_ntp_response
will die (so call get_ntp_response in an eval block).

=head1 SEE ALSO

perl, IO::Socket, RFC5905, RFC1305, RFC2030

=head1 AUTHOR

Now maintained by Ask Bjørn Hansen, E<lt>ask@develooper.com<gt>

Originally by James G. Willmore, E<lt>jwillmore (at) adelphia.net<gt>
or E<lt>owner (at) ljcomputing.net<gt>

Special thanks to Ralf D. Kloth E<lt>ralf (at) qrq.de<gt> for the code
to decode NTP packets.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Ask Bjørn Hansen; 2004 by James G. Willmore

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package Net::NTP::Packet;

=head1 NAME

Net::NTP::Packet

=head1 DESCRIPTION

Representation of a NTP Packet with serialization primitives.

=head2 PROTOCOL - RFC 5905 - Section 7.

       0                   1                   2                   3
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |LI | VN  |Mode |    Stratum     |     Poll      |  Precision   |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                         Root Delay                            |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                         Root Dispersion                       |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                          Reference ID                         |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                     Reference Timestamp (64)                  +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                      Origin Timestamp (64)                    +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                      Receive Timestamp (64)                   +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                      Transmit Timestamp (64)                  +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      .                                                               .
      .                    Extension Field 1 (variable)               .
      .                                                               .
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      .                                                               .
      .                    Extension Field 2 (variable)               .
      .                                                               .
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                          Key Identifier                       |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                            dgst (128)                         |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
=cut

=head2 new

create a new Net::NTP::Packet instance.

Parameters are the field names, gotten from "7.3.  Packet Header Variables"

=cut

sub new {
    my $class = shift;
    my(%param) = @_;

    my %self = ();

    foreach my $k (@_ntp_packet_field_names) {
       $self{$k} = delete $param{$k};
    }

    if (keys %param) {
        die "unknown fields: ", join(", ", keys %param);
    }
    return bless \%self, $class;
}

=head2 new_client_packet($xmttime)

Make a packet in association mode 'Client' to be sent to a server.

=cut

sub new_client_packet {
    my $class = shift;
    my $xmttime = shift || die "a transmit time is required.";
    return $class->new(
        version => 4,
        org => $xmttime,
    );
}

=head2 encode()

Encode a packet to its wire format.
NOTE: It only encodes server packets at the moment.

=cut

sub encode {
    my $self = shift;
    my $t1 = $self->{org};
    my $client_adj_localtime = $t1 + Net::NTP::NTP_ADJ;
    my $client_frac_localtime = _frac2bin($client_adj_localtime);
    ## LI=0, VN=3, MODE=3, Stratum,Poll,Precision=0, ...
    return pack("B8 C3 N9 N B32", '00011011', (0) x 3, (0) x 9, int($client_adj_localtime), $client_frac_localtime);
}

=head2 $packet = Net::NTP::Packet->decode($data, $xmttime, $rectime)

decode the NTP packet from its wire format.

=cut

my @ntp_fields = qw/byte1 stratum poll precision/;
push @ntp_fields, qw/delay delay_fb disp disp_fb ident/;
push @ntp_fields, qw/ref_time ref_time_fb/;
push @ntp_fields, qw/org_time org_time_fb/;
push @ntp_fields, qw/recv_time recv_time_fb/;
push @ntp_fields, qw/trans_time trans_time_fb/;

sub decode {
    my $class = shift;
    my $data = shift || die "decode() needs data.";
    my $timestamp = shift || die "decode() takes a timestamp.";

    my %tmp_pkt;
    @tmp_pkt{@ntp_fields} = unpack("a C2 c   n B16 n B16 H8   N B32 N B32   N B32 N B32", $data);

    return $class->new(
        leap => (unpack("C", $tmp_pkt{byte1} & "\xC0") >> 6),
        version => (unpack("C", $tmp_pkt{byte1} & "\x38") >> 3),
        mode => unpack("C", $tmp_pkt{byte1} & "\x07"),
        stratum => $tmp_pkt{stratum},
        poll => $tmp_pkt{poll},
        precision => $tmp_pkt{precision},
        rootdelay => _bin2frac($tmp_pkt{delay_fb}),
        rootdisp => $tmp_pkt{disp},
        refid => _unpack_refid($tmp_pkt{stratum}, $tmp_pkt{ident}),
        reftime => $tmp_pkt{ref_time} + _bin2frac($tmp_pkt{ref_time_fb}) - Net::NTP::NTP_ADJ,
        org => $tmp_pkt{org_time} + _bin2frac($tmp_pkt{org_time_fb}) - Net::NTP::NTP_ADJ,
        rec => $tmp_pkt{recv_time} + _bin2frac($tmp_pkt{recv_time_fb}) - Net::NTP::NTP_ADJ,
        xmt => $tmp_pkt{trans_time} + _bin2frac($tmp_pkt{trans_time_fb}) - Net::NTP::NTP_ADJ,
        dst => $timestamp,
        keyid => '',
        dgst => '',
    );
}


sub _unpack_refid {
    my $stratum = shift;
    my $raw_id  = shift;
    if ($stratum < 2) {
        return unpack("A4", pack("H8", $raw_id));
    }
    return sprintf("%d.%d.%d.%d", unpack("C4", pack("H8", $raw_id)));
}

sub _frac2bin {
    my $bin  = '';
    my $frac = shift;
    while (length($bin) < 32) {
        $bin = $bin . int($frac * 2);
        $frac = ($frac * 2) - (int($frac * 2));
    }
    return $bin;
}

sub _bin2frac {
    my @bin = split '', shift;
    my $frac = 0;
    while (@bin) {
        $frac = ($frac + pop @bin) / 2;
    }
    return $frac;
};

1;
