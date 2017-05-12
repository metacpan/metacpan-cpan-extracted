#!/usr/bin/perl -w
package Net::BitTorrent::Torrent::Tracker::UDP;
{
    use strict;
    use warnings;
    use Carp qw[carp];
    use Scalar::Util qw[blessed weaken refaddr];
    use List::Util qw[sum];
    use Socket qw[inet_aton pack_sockaddr_in];
    use lib q[../../../../../lib];
    use Net::BitTorrent::Util qw[:compact];
    use version qw[qv];
    our $VERSION_BASE = 50; our $UNSTABLE_RELEASE = 0; our $VERSION = sprintf(($UNSTABLE_RELEASE ? q[%.3f_%03d] : q[%.3f]), (version->new(($VERSION_BASE))->numify / 1000), $UNSTABLE_RELEASE);
    my %REGISTRY = ();
    my @CONTENTS = \my (%_url,                  %_tier,
                        %_tid,                  %_cid,
                        %_outstanding_requests, %_packed_host,
                        %_event,                %_peers,
                        %_complete,             %_incomplete
    );

    sub new {
        my ($class, $args) = @_;
        if (!$args) {
            carp q[Net::[...]Tracker::UDP->new({}) requires params];
            return;
        }
        if ((!$args->{q[URL]}) || ($args->{q[URL]} !~ m[^udp://]i)) {
            carp q[Net::[...]Tracker::UDP->new({}) requires a valid URL];
            return;
        }
        if (   (!$args->{q[Tier]})
            || (!$args->{q[Tier]}->isa(q[Net::BitTorrent::Torrent::Tracker])))
        {   carp q[Net::[...]Tracker::UDP->new({}) requires a parent Tracker];
            return;
        }
        my $self = bless \$args->{q[URL]}, $class;
        my ($host, $port, $path)
            = $args->{q[URL]} =~ m{^udp://([^/:]*)(?::(\d+))?(/.*)$};
        $port = $port ? $port : 80;
        my $packed_host = undef;
        if ($host
            !~ m[^(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]?){4})$])
        {   my ($name, $aliases, $addrtype, $length, @addrs)
                = gethostbyname($host)
                or return;
            $packed_host = $addrs[0];
        }
        else { $packed_host = inet_aton($host) }
        $_packed_host{refaddr $self}
            = pack_sockaddr_in($port, inet_aton($host));
        $_url{refaddr $self}        = $args->{q[URL]};
        $_event{refaddr $self}      = q[];
        $_tier{refaddr $self}       = $args->{q[Tier]};
        $_peers{refaddr $self}      = q[];
        $_complete{refaddr $self}   = 0;
        $_incomplete{refaddr $self} = 0;
        $_tid{refaddr $self}        = int(rand() * 26**5);
        weaken $_tier{refaddr $self};
        weaken($REGISTRY{refaddr $self} = $self);
        return $self;
    }

    # Accessors | Public
    sub url { my ($self) = @_; return $_url{refaddr $self}; }

    # Accessors | Private
    sub _packed_host { return $_packed_host{refaddr +shift} }
    sub _tier        { return $_tier{refaddr +shift}; }
    sub _peers       { return $_peers{refaddr +shift}; }
    sub _client      { return $_tier{refaddr +shift}->_client }

    # Methods | Private
    sub _announce {
        my ($self, $event) = @_;
        if (!$_tier{refaddr $self}->_client->_udp) {
            carp sprintf q[UDP port is not open];
            $_tier{refaddr $self}->_shuffle();
            return;
        }
        if (defined $event) {
            if ($event !~ m[^(?:st(?:art|opp)|complet)ed$]) {
                carp sprintf q[Invalid event for announce: %s], $event;
                return;
            }
            $_event{refaddr $self} = $event;
        }
        my $tid = $self->_generate_token_id();
        if (not $_cid{refaddr $self}) {
            my $packet = pack q[a8NN], ___pack64(4497486125440), 0, $tid;
            $_outstanding_requests{refaddr $self}{$tid} = {Timestamp => time,
                                                           Attempt   => 1,
                                                           Packet => $packet
            };
        }
        else {
            my $packet = pack q[a8NN]
                . q[a20 a20 a8 a8 a8 N N N N n],
                $_cid{refaddr $self}, 1, $tid,
                pack(q[H*], $_tier{refaddr $self}->_torrent->infohash),
                $self->_client->peerid(),
                ___pack64($_tier{refaddr $self}->_torrent->downloaded()),
                ___pack64(
                     $_tier{refaddr $self}->_torrent->raw_data(1)
                         ->{q[info]}{q[piece length]} * sum(
                         split(q[],
                               unpack(
                                   q[b*],
                                   ($_tier{refaddr $self}->_torrent->_wanted()
                                        || q[]
                                   )
                               )
                         )
                         )
                ),
                ___pack64($_tier{refaddr $self}->_torrent->uploaded()),
                (  $_event{refaddr $self} eq q[completed] ? 1
                 : $_event{refaddr $self} eq q[started]   ? 2
                 : $_event{refaddr $self} eq q[stopped]   ? 3
                 : 0
                ),
                0, $^T, 200, $self->_client->_tcp_port
                || 0;
            $_outstanding_requests{refaddr $self}{$tid} = {Timestamp => time,
                                                           Attempt   => 1,
                                                           Packet => $packet,
                                                           Retry_ID => q[]
            };
        }
        $self->_send($tid);
    }

    sub _send {
        my ($self, $tid) = @_;
        if (!$_tier{refaddr $self}->_client->_udp) {
            $self->_client->_socket_open();
        }
        return if not $self->_client->_udp;
        if ($_outstanding_requests{refaddr $self}{$tid}{q[Attempt]} > 8) {
            delete $_outstanding_requests{refaddr $self}{$tid};
            return;
        }
        if (not send($_tier{refaddr $self}->_client->_udp,
                     $_outstanding_requests{refaddr $self}{$tid}{q[Packet]},
                     0,
                     $_packed_host{refaddr $self}
            )
            )
        {   carp sprintf(
                    q[Cannot send %d bytes to %s: [%d] %s],
                    length(
                        $_outstanding_requests{refaddr $self}{$tid}{q[Packet]}
                    ),
                    q[TODO], $^E, $^E
            );
            return;
        }
        $_tier{refaddr $self}->_torrent->_event(
                                         q[tracker_connect],
                                         {Tracker => $self,
                                          ($_event{refaddr $self}
                                           ? (Event => $_event{refaddr $self})
                                           : ()
                                          )
                                         }
        );
        $_tier{refaddr $self}->_torrent->_event(
                   q[tracker_write],
                   {Tracker => $self,
                    Length  => length(
                        $_outstanding_requests{refaddr $self}{$tid}{q[Packet]}
                    )
                   }
        );
        $_outstanding_requests{refaddr $self}{$tid}{q[Retry_ID]}
            = $self->_client->_schedule(
            {Time =>
                 time + (15 * (2**$_outstanding_requests{refaddr $self}{$tid}
                                   {q[Attempt]}
                         )
                 ),
             Code => sub {
                 $_outstanding_requests{refaddr $self}{$tid}{q[Attempt]}++;
                 shift->_send($tid);
             },
             Object => $self
            }
            );
        return 1;
    }

    sub _on_data {
        my ($self, $paddr, $data) = @_;
        my ($action, $tid, $packet) = unpack q[NNa*], $data;
        $_tier{refaddr $self}->_torrent->_event(q[tracker_read],
                                 {Tracker => $self, Length => length($data)});
        return if not $_outstanding_requests{refaddr $self}{$tid};
        my $_request = $_outstanding_requests{refaddr $self}{$tid};
        $self->_client->_cancel(
                    $_outstanding_requests{refaddr $self}{$tid}{q[Retry_ID]});
        delete $_outstanding_requests{refaddr $self}{$tid};
        if ($action == 0) {

            if (length($data) == 16) {
                my ($cid) = unpack(q[a8], $packet);
                $_cid{refaddr $self} = $cid;
                $self->_announce();
                return $self;
            }
            return;
        }
        elsif ($action == 1) {
            if (length($data) >= 20) {
                my ($min_interval, $leeches, $seeds, $peers)
                    = unpack(q[N N N a*], $packet);
                $_peers{refaddr $self}      = $peers;
                $_complete{refaddr $self}   = $seeds;
                $_incomplete{refaddr $self} = $leeches;
                $_tier{refaddr $self}->_torrent->_event(
                                            q[tracker_success],
                                            {Tracker => $self,
                                             Payload => {
                                                 complete     => $seeds,
                                                 incomplete   => $leeches,
                                                 peers        => $peers,
                                                 min_interval => $min_interval
                                             }
                                            }
                );
                $self->_client->_schedule(
                    {   Time => (time + (  $min_interval
                                         ? $min_interval
                                         : 1800
                                 )
                        ),
                        Code =>
                            sub { return $_tier{refaddr +shift}->_announce() }
                        ,
                        Object => $self
                    }
                );
            }
            $_event{refaddr $self} = q[];
            return $self;
        }
        elsif ($action == 2) {
        }
        elsif ($action == 3) {
            $_tier{refaddr $self}->_torrent->_event(q[tracker_failure],
                                                    {Tracker => $self,
                                                     Reason  => $packet
                                                    }
            );
            $self->_client->_schedule(
                {Time => time + 30,
                 Code => sub {
                     my ($s) = @_;
                     $s->_tier->_shuffle;
                     return $s->_tier->_announce();
                 },
                 Object => $self
                }
            );
            return;
        }
        else { }
        return;
    }

    sub _generate_token_id {
        return if defined $_[1];
        my ($self) = @_;
        my ($len) = ($_tid{refaddr $self} =~ m[^(\d+)]);
        $_tid{refaddr $self}
            = ($_tid{refaddr $self} >= (26**5) ? 0 : ++$_tid{refaddr $self});
        return $_tid{refaddr $self};
    }

    sub as_string {
        my ($self, $advanced) = @_;
        my $dump = !$advanced ? $$self : sprintf <<'END',
Net::BitTorrent::Torrent::Tracker::UDP

URL: %s
END
            $_url{refaddr $self};
        return defined wantarray ? $dump : print STDERR qq[$dump\n];
    }

    sub ___pack64 {    # [id://163389]
        my ($value) = @_;
        my $return;
        if (!eval { $return = pack(q[Q], $value); 1; }) {
            require Math::BigInt;
            my $i = new Math::BigInt $value;
            my ($int1, $int2) = do {
                if ($i < 0) {
                    $i = -1 - $i;
                    (~(int($i / 2**32) % 2**32), ~int($i % 2**32));
                }
                else {
                    (int($i / 2**32) % 2**32, int($i % 2**32));
                }
            };
            $return = pack(q[NN], $int1, $int2);
        }
        return $return;
    }

    sub CLONE {
        for my $_oID (keys %REGISTRY) {
            my $_obj = $REGISTRY{$_oID};
            my $_nID = refaddr $_obj;
            for (@CONTENTS) {
                $_->{$_nID} = $_->{$_oID};
                delete $_->{$_oID};
            }
            weaken $_tier{$_nID};
            weaken($REGISTRY{$_nID} = $_obj);
            delete $REGISTRY{$_oID};
        }
        return 1;
    }
    DESTROY {
        my ($self) = @_;
        for (@CONTENTS) { delete $_->{refaddr $self}; }
        delete $REGISTRY{refaddr $self};
        return 1;
    }
    1;
}

=pod

=head1 NAME

Net::BitTorrent::Torrent::Tracker::UDP - Single UDP BitTorrent Tracker

=head1 Constructor

=over 4

=item C<new ( [ARGS] )>

Creates a C<Net::BitTorrent::Torrent::Tracker::UDP> object.  This
constructor should not be used directly.

=back

=head1 Methods

=over

=item C<url ( )>

Returns the related UDP 'URL' according to the original metadata.

=item C<as_string ( [ VERBOSE ] )>

Returns a 'ready to print' dump of the  object's data structure.  If
called in void context, the structure is printed to C<STDERR>.
C<VERBOSE> is a boolean value.

=back

=head1 BUGS/TODO

=over 4

=item *

This is ALPHA code and as such may not work as expected.

=item *

Should I pretend UDP uses connections and trigger the 'tracker_connect'
callback whenever we send() data just to keep things even?

=back

=head1 See Also

=over

=item BEP 15

UDP Tracker Protocol for BitTorrent
http://bittorrent.org/beps/bep_0015.html

=back

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

=for svn $Id: UDP.pm d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
