#!/usr/bin/perl -w
package Net::BitTorrent::Torrent::Tracker::HTTP;
{
    use strict;
    use warnings;
    use Carp qw[carp];
    use Scalar::Util qw[blessed weaken refaddr];
    use List::Util qw[sum];
    use Socket qw[PF_INET SOMAXCONN SOCK_STREAM inet_aton pack_sockaddr_in];
    use Fcntl qw[F_SETFL O_NONBLOCK];
    use lib q[../../../../../lib];
    use Net::BitTorrent::Util qw[:bencode :compact];
    use version qw[qv];
    our $VERSION_BASE = 50; our $UNSTABLE_RELEASE = 0; our $VERSION = sprintf(($UNSTABLE_RELEASE ? q[%.3f_%03d] : q[%.3f]), (version->new(($VERSION_BASE))->numify / 1000), $UNSTABLE_RELEASE);
    my (@CONTENTS)
        = \my (%_url,   %_tier,     %resolve,
               %_event, %_socket,   %_data_out,
               %_peers, %_complete, %_incomplete
        );
    my %REGISTRY;

    sub new {
        my ($class, $args) = @_;
        if (!$args) {
            carp q[Net::[...]Tracker::HTTP->new({}) requires params];
            return;
        }
        if ((!$args->{q[URL]}) || ($args->{q[URL]} !~ m[^http://]i)) {
            carp q[Net::[...]Tracker::HTTP->new({}) requires a valid URL];
            return;
        }
        if (   (!$args->{q[Tier]})
            || (!$args->{q[Tier]}->isa(q[Net::BitTorrent::Torrent::Tracker])))
        {   carp
                q[Net::[...]Tracker::HTTP->new({}) requires a parent Tracker];
            return;
        }
        my $self = bless \$args->{q[URL]}, $class;
        $_url{refaddr $self}        = $args->{q[URL]};
        $_tier{refaddr $self}       = $args->{q[Tier]};
        $_peers{refaddr $self}      = q[];
        $_complete{refaddr $self}   = 0;
        $_incomplete{refaddr $self} = 0;
        weaken $_tier{refaddr $self};
        weaken($REGISTRY{refaddr $self} = $self);
        return $self;
    }

    # Accessors | Public
    sub url { my ($self) = @_; return $_url{refaddr $self}; }

    # Accesors | Private
    sub _socket { return $_socket{refaddr +shift}; }
    sub _tier   { return $_tier{refaddr +shift}; }
    sub _peers  { return $_peers{refaddr +shift}; }
    sub _client { return $_tier{refaddr +shift}->_client }

    # Methods | Private
    sub _announce {
        my ($self, $event) = @_;

        #warn sprintf q[_announce(%s)], $event? qq['$event']:q[];
        if (defined $event) {
            if ($event !~ m[^(?:st(?:art|opp)|complet)ed$]) {
                carp sprintf q[Invalid event for announce: %s], $event;
                return;
            }
            $_event{refaddr $self} = $event;
        }
        my ($host, $port, $path)
            = $_url{refaddr $self} =~ m{^http://([^/:]*)(?::(\d+))?(/.*)$};
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
        socket($_socket{refaddr $self},
               PF_INET, SOCK_STREAM, getprotobyname(q[tcp]))
            or return;
        if (not($^O eq q[MSWin32]
                ? ioctl($_socket{refaddr $self}, 0x8004667e, pack(q[I], 1))
                : fcntl($_socket{refaddr $self}, F_SETFL, O_NONBLOCK)
            )
            )
        {   $_tier{refaddr $self}->_torrent->_event(
                q[tracker_failure],
                {Tracker => $self,
                 Reason  => sprintf(
                     q[There was a problem making an outgoing socket non-blocking: [%d] %s],
                     $^E, $^E
                 )
                }
            );
            return;
        }
        my $_inet_aton = inet_aton($host);
        if (!$_inet_aton) {
            $_tier{refaddr $self}->_torrent->_event(
                         q[tracker_failure],
                         {Tracker => $self,
                          Reason => sprintf(q[Cannot resolve host: %s], $host)
                         }
            );
            return;
        }
        my $pack_sockaddr_in = pack_sockaddr_in($port, $_inet_aton);
        if (!$pack_sockaddr_in) {
            $_tier{refaddr $self}->_torrent->_event(
                         q[tracker_failure],
                         {Tracker => $self,
                          Reason => sprintf(q[Cannot resolve host: %s], $host)
                         }
            );
            return;
        }
        connect($_socket{refaddr $self}, $pack_sockaddr_in);
        $_tier{refaddr $self}->_torrent->_event(q[tracker_connect],
                                                {Tracker => $self,
                                                 (defined $event
                                                  ? (Event => $event)
                                                  : ()
                                                 )
                                                }
        );
        my $infohash = $_tier{refaddr $self}->_torrent->infohash;
        $infohash =~ s|(..)|\%$1|g;
        my %query_hash = (
            q[info_hash] => $infohash,
            q[peer_id]   => $_tier{refaddr $self}->_client->peerid(),
            q[port]     => ($_tier{refaddr $self}->_client->_tcp_port() || 0),
            q[uploaded] => $_tier{refaddr $self}->_torrent->uploaded(),
            q[downloaded] => $_tier{refaddr $self}->_torrent->downloaded(),
            q[left]       => (
                $_tier{refaddr $self}->_torrent->raw_data(1)
                    ->{q[info]}{q[piece length]} * sum(
                    split(
                        q[],
                        unpack(
                            q[b*],
                            ($_tier{refaddr $self}->_torrent->_wanted() || q[]
                            )
                        )
                    )
                    )
            ),
            q[key]        => $^T,
            q[numwant]    => 200,
            q[compact]    => 1,
            q[no_peer_id] => 1,
            ($_event{refaddr $self}
             ? (q[event] => $_event{refaddr $self})
             : ()
            )
        );
        my $url 
            = $path 
            . ($path =~ m[\?] ? q[&] : q[?])
            . (join q[&],
               map { sprintf q[%s=%s], $_, $query_hash{$_} }
                   sort keys %query_hash
            );
        $_data_out{refaddr $self} =
            join(qq[\015\012],
                 qq[GET $url HTTP/1.0],
                 q[Connection: close],
                 qq[Host: $host:$port],
                 q[Accept: text/plain],
                 q[Accept-Encoding:],
                 qq[User-Agent: Net::BitTorrent/] . $Net::BitTorrent::VERSION,
                 q[],
                 q[]);
        $_tier{refaddr $self}->_client->_remove_connection($self);
        return $_tier{refaddr $self}->_client->_add_connection($self, q[wo]);
    }

    sub _rw {
        my ($self, $read, $write, $error) = @_;

#Carp::cluck sprintf q[%s->_rw(%d, %d, %d)], __PACKAGE__, $read, $write, $error;
        my ($actual_read, $actual_write) = (0, 0);
        return if not defined $_tier{refaddr $self}->_client;
        if ($error) {
            $_tier{refaddr $self}->_client->_remove_connection($self);
            shutdown($_socket{refaddr $self}, 2);
            close $_socket{refaddr $self};
            $_tier{refaddr $self}->_client->_schedule(
                {   Time => time + 30,
                    Code => sub {
                        my ($s) = @_;
                        $_tier{refaddr $s}->_shuffle;
                        return $_tier{refaddr $s}->_announce();
                    },
                    Object => $self
                }
            );
            return;
        }
        elsif ($write) {
            $actual_write = syswrite($_socket{refaddr $self},
                                     $_data_out{refaddr $self}, $write);
            if (!$actual_write) {
                $_tier{refaddr $self}->_torrent->_event(
                       q[tracker_failure],
                       {Tracker => $self,
                        Reason => sprintf(q[Cannot write to tracker: %s], $^E)
                       }
                );
                $_tier{refaddr $self}->_client->_remove_connection($self);
                shutdown($_socket{refaddr $self}, 2);
                close $_socket{refaddr $self};
                $_tier{refaddr $self}->_client->_schedule(
                    {   Time => time + 300,
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
            $_tier{refaddr $self}->_torrent->_event(q[tracker_write],
                                 {Tracker => $self, Length => $actual_write});
            substr($_data_out{refaddr $self}, 0, $actual_write, q[]);
            if (!length $_data_out{refaddr $self}) {
                shutdown($_socket{refaddr $self}, 1);
                $_tier{refaddr $self}->_client->_remove_connection($self);
                $_tier{refaddr $self}->_client->_add_connection($self, q[ro]);
            }
        }
        elsif ($read) {
            $actual_read
                = sysread($_socket{refaddr $self}, my ($data), $read, 0);
            if (not $actual_read) {
                $_tier{refaddr $self}->_torrent->_event(
                      q[tracker_failure],
                      {Tracker => $self,
                       Reason => sprintf(q[Cannot read from tracker: %s], $^E)
                      }
                );
                $_tier{refaddr $self}->_client->_remove_connection($self);
                shutdown($_socket{refaddr $self}, 2);
                close $_socket{refaddr $self};
                $_tier{refaddr $self}->_client->_schedule(
                    {   Time => time + 300,
                        Code => sub {
                            my ($s) = @_;
                            $_tier{refaddr $s}->_shuffle;
                            return $_tier{refaddr $s}->_announce();
                        },
                        Object => $self
                    }
                );
                return;
            }
            else {
                $_tier{refaddr $self}->_torrent->_event(q[tracker_read],
                                  {Tracker => $self, Length => $actual_read});
                $data =~ s[^.+(?:\015?\012){2}][]s;
                $data = bdecode($data);
                if ($data) {
                    if (defined $data->{q[failure reason]}) {
                        $_tier{refaddr $self}->_torrent->_event(
                                         q[tracker_failure],
                                         {Tracker => $self,
                                          Reason => $data->{q[failure reason]}
                                         }
                        );
                    }
                    else {
                        $_peers{refaddr $self}      = $data->{q[peers]};
                        $_complete{refaddr $self}   = $data->{q[complete]};
                        $_incomplete{refaddr $self} = $data->{q[incomplete]};
                        $_tier{refaddr $self}
                            ->_torrent->_event(q[tracker_success],
                                        {Tracker => $self, Payload => $data});
                        delete $_event{refaddr $self};
                    }
                }
                $_tier{refaddr $self}->_client->_schedule(
                    {   Time => (time + (defined $data->{q[interval]}
                                         ? $data->{q[interval]}
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
            $_tier{refaddr $self}->_client->_remove_connection($self);
            shutdown($_socket{refaddr $self}, 2);
            close $_socket{refaddr $self};
            $_tier{refaddr $self}
                ->_torrent->_event(q[tracker_disconnect], {Tracker => $self});
        }
        else {
            $_tier{refaddr $self}->_torrent->_event(
                                     q[tracker_failure],
                                     {Tracker => $self,
                                      Reason => q[Failed to read from tracker]
                                     }
            );
            $_tier{refaddr $self}->_client->_schedule(
                  { Time => time + 300,
                    Code =>
                        sub { return $_tier{refaddr +shift}->_announce(); },
                    Object => $self
                  }
            );
            return;
        }
        return ($actual_read, $actual_write);
    }

    sub as_string {
        my ($self, $advanced) = @_;
        my $dump = !$advanced ? $$self : sprintf <<'END',
Net::BitTorrent::Torrent::Tracker::HTTP

URL: %s
END
            $_url{refaddr $self};
        return defined wantarray ? $dump : print STDERR qq[$dump\n];
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
        return delete $REGISTRY{refaddr $self};
    }
    1;
}

=pod

=head1 NAME

Net::BitTorrent::Torrent::Tracker::HTTP - Single HTTP BitTorrent Tracker

=head1 Constructor

=over 4

=item C<new ( [ARGS] )>

Creates a C<Net::BitTorrent::Torrent::Tracker::HTTP> object.  This
constructor should not be used directly.

=back

=head1 Methods

=over

=item C<url ( )>

Returns the related HTTP URL according to the original metadata.

=item C<as_string ( [ VERBOSE ] )>

Returns a 'ready to print' dump of the  object's data structure.  If
called in void context, the structure is printed to C<STDERR>.
C<VERBOSE> is a boolean value.

=back

=head1 BUGS/TODO

=over 4

=item *

Does not support HTTPS trackers.

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

=for svn $Id: HTTP.pm d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
