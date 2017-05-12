#!perl -w -I../lib
use strict;
use warnings;
use Net::BitTorrent;
use Data::Dumper;
use Time::HiRes qw[time sleep];
$|++;
my $OLD_STDERR = \*STDERR;
open *STDERR, q[>], q[net-bittorrent.log]
    or die q[Failed to create log: ] . $^E;

sub l {    # logs events
    my ($line) = @_;
    syswrite STDOUT, $line . qq[\r\n];
    syswrite STDERR, sprintf <<END, time, $line }
%10.8f ===========================================================
%s
END
l q[Load];
my $client = Net::BitTorrent->new();

sub p {
    l q[Current peers...];
    l join qq[ ----------\r\n], map { $_->{q[Object]}->as_string(1) } grep {
                $_->{q[Object]}
            and $_->{q[Object]}->isa(q[Net::BitTorrent::Peer])
    } values %{$client->_connections};
}
l $client->as_string(1);
my $file = shift;
l sprintf q[Loading '%s'], $file;
my $torrent = $client->add_torrent({Path => $file});
if (!$torrent) {
    l sprintf q[Failed to load '%s'], $torrent;
    l q[Exiting...];
    exit;
}
l q[Loaded torrent okay. Raw data follows...];
l Dumper $torrent->raw_data(1);
l q[Setting client-wide callbacks...];
$client->on_event(
    q[ip_filter],
    sub {
        my ($self, $args) = @_;
        l q[ ip_filter          | ] . $args->{q[Address]};
        p;
    }
);
$client->on_event(q[peer_connect],
                  sub { l q[ peer_connect       | ] . Dumper \@_; p; });
$client->on_event(q[peer_disconnect],
                  sub { l q[ peer_disconnect    | ] . Dumper \@_; p; });
$client->on_event(
    q[peer_read],
    sub {
        l q[ peer_read          | ] . Dumper \@_;
    }
);
$client->on_event(q[peer_write],
                  sub { l q[ peer_write         | ] . Dumper \@_; });
$client->on_event(q[tracker_connect],
                  sub { l q[ tracker_connect    | ] . Dumper \@_; });
$client->on_event(q[tracker_disconnect],
                  sub { l q[ tracker_disconnect | ] . Dumper \@_; });
$client->on_event(q[tracker_read],
                  sub { l q[ tracker_read       | ] . Dumper \@_; });
$client->on_event(q[tracker_write],
                  sub { l q[ tracker_write      | ] . Dumper \@_; });
$client->on_event(q[tracker_success],
                  sub { l q[ tracker_success    | ] . Dumper \@_; });
$client->on_event(q[tracker_failure],
                  sub { l q[ tracker_failure    | ] . Dumper \@_; });
$client->on_event(
    q[piece_hash_pass],
    sub {
        my ($self, $args) = @_;
        l q[ piece_hash_pass    | ] . $args->{q[Index]};
        l $args->{q[Torrent]}->as_string(1);
    }
);
$client->on_event(
    q[piece_hash_fail],
    sub {
        my ($self, $args) = @_;
        l q[ piece_hash_fail    | ] . $args->{q[Index]};
        l $args->{q[Torrent]}->as_string(1);
    }
);
$client->on_event(q[file_open],
                  sub { l q[ file_open          | ] . Dumper \@_; });
$client->on_event(q[file_close],
                  sub { l q[ file_close         | ] . Dumper \@_; });
$client->on_event(q[file_read],
                  sub { l q[ file_read          | ] . Dumper \@_; });
$client->on_event(q[file_write],
                  sub { l q[ file_write         | ] . Dumper \@_; });
$client->on_event(q[file_error],
                  sub { l q[ file_error         | ] . Dumper \@_; });

sub packet_type {
    my $t = shift;
    return q[Handshake]        if $t == -1;
    return q[Keepalive]        if $t == q[];
    return q[Choke]            if $t == 0;
    return q[Unchoke]          if $t == 1;
    return q[Interested]       if $t == 2;
    return q[Not interested]   if $t == 3;
    return q[Have]             if $t == 4;
    return q[Bitfield]         if $t == 5;
    return q[Request]          if $t == 6;
    return q[Piece]            if $t == 7;
    return q[Cancel]           if $t == 8;
    return q[Port]             if $t == 9;
    return q[Suggest]          if $t == 13;
    return q[Have all]         if $t == 14;
    return q[Have none]        if $t == 15;
    return q[Reject]           if $t == 16;
    return q[Allowed fast set] if $t == 17;
    return q[ExtProtocol]      if $t == 20;
    return q[Unknown];
}
$client->on_event(
    q[incoming_packet],
    sub {
        my ($self, $args) = @_;
        l sprintf
            q[ incoming_packet    | Type: %d (%s) | Payload: %s | From: %s],
            $args->{q[Type]}, packet_type($args->{q[Type]}),
            (keys %{$args->{q[Payload]}}
             ? Dumper($args->{q[Payload]})
             : q[NA]
            ),
            $args->{q[Peer]}->as_string(1);
    }
);
$client->on_event(
    q[outgoing_packet],
    sub {
        my ($self, $args) = @_;
        l sprintf
            q[ outoming_packet   | Type: %d (%s) | Payload: %s | To: %s],
            $args->{q[Type]}, packet_type($args->{q[Type]}),
            (keys %{$args->{q[Payload]}}
             ? Dumper($args->{q[Payload]})
             : q[NA]
            ),
            $args->{q[Peer]}->as_string(1);
    }
);

# make sure everything's okay...
l q[hashchecking...];
$torrent->hashcheck;
l q[forcing the torrent to start];
$torrent->start;
l $torrent->as_string(1);
l q[starting event loop...];
$client->do_one_loop(0.25) && sleep(0.50) while !$torrent->is_complete;
l q[Exiting];

=pod

=head1 NAME

002-debug.pl - Demonstration script that logs EVERYTHING

=head1 Description

This logs every bit of information useful in debugging and should not be
used under normal circumstances.  Logged data is stored in
C<net-bittorrent.log>.

=head1 Synopsis

 002-debug.pl some.torrent

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

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

=for svn $Id: 002-debug.pl d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
