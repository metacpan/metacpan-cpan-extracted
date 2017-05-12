package Net::Analysis::Listener::TCP;
# $Id: TCP.pm 133 2005-10-02 18:45:28Z abworrall $

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;

use Carp qw(carp croak confess);

use Params::Validate qw(:all);

use Net::Analysis::Constants qw(:tcpflags);
use Net::Analysis::Packet qw(:all);
use Net::Analysis::TCPSession qw(:const);

use base qw(Net::Analysis::Listener::Base);

# {{{ POD

=head1 NAME

Net::Analysis::Listener::TCP - listens to packets, emits streams

=head1 SYNOPSIS

This module subclasses Net::Analysis::Listener::Base, and manages TCP sessions
behind the scenes.

Listens for:
  _internal_tcp_packet - note: augments packet, for downstream listeners

Emits:
  tcp_session_start
  tcp_session_end
  tcp_monologue     - a series of data packets

=head1 DESCRIPTION

Each raw packet is slotted into the relevant TCP session. The TCPSession module
does most of the analysis on the packet, allowing this one to emit
C<tcp_monologue> events as they are completed.

The tcp_monologue event is the backbone of higher level protocol analysers. It
is not a good example for writing your own listener.

=head1 CONFIGURATION

 v - verbosity; a bitmask for logging to stdout:
      0x01 - per-packet
      0x02 - per-monologue
      0x04 - per-session

 k - a TCP-session key to suddenly get verbose about 

 dump - dumps out monologues as files into the current directory

 max_session_size - discard packets once this many bytes have been seen

=head1 EMITTED EVENTS

=head2 C<tcp_session_start>

Emitted when we see a new TCP session get successfully estabished. Contains the
following arguments:

 socketpair_key - uniquely identifies the TCP session
 pkt            - the Net::Analysis::Packet which established the session

Note that C<pkt> is the final packet in the setup handshake; it is not the
initail SYN, or the first data packet. You can get the SYN packets from the
TCPSession object if you want to dig around.

=head2 C<tcp_session_end>

Emitted when we see the end of the session; either because of a proper
handshake, or because we ran out of data. Contains the
following arguments:

 socketpair_key - uniquely identifies the TCP session
 pkt            - the Net::Analysis::Packet which closed the session

Note that C<pkt> will be C<undef> if we ran out of data.

=head2 C<tcp_monologue>

As packets travel in one direction, we gather them up. When we see a (data)
packet in the other direction, or the end of the TCP session, we combine the
gathered packetes into a monologue object and emit this event. Contains the
following arguments:

 socketpair_key - uniquely identifies the TCP session
 monologue      - a Net::Analysis::TCPMonologue object

=head1 METHODS

You probably don't need to read the rest of this ...

=cut

# }}}

#### Non-standard override stuff
#
# {{{ new

=head2 new ( )

Simple wrapper on top of C<Listener::Base::new()>, which ensures that the
TCP listener is put first in the queue for listening to events.

This queue-jumping is to allow the C<tcp_packet> handler to add extra info to
the packet that higher level analysers might want to see. This info is derived
from its state in the TCP session.

=cut

sub new {
    my $self = shift;

    return $self->SUPER::new(@_, pos => 'first');  #
}

# }}}


#### Callbacks
#
# {{{ validate_configuration

sub validate_configuration {
    my $self = shift;

    my %h = validate (@_, { v     => {type => SCALAR,
                                      default => 0},
                            dump  => {type => SCALAR,
                                      default => 0},
                            max_session_size => {type => SCALAR,
                                                 default => 0},
                            k     => {type => SCALAR,
                                      default => ''},
                          });

    return \%h;
}

# }}}

# {{{ setup

sub setup {
    my ($self) = shift;

    $self->trace ("======[--:--:--.------] TCP setup") if ($self->{v} & 0x08);

    $self->{active_tcp_sessions}   = {};
}

# }}}
# {{{ teardown

sub teardown {
    my ($self) = shift;

    # If anything is still open, finish it off - we have no more packets
    foreach my $k (keys %{$self->{active_tcp_sessions}}) {
        my $sesh = $self->_get_session_object($k);

        if ($sesh->has_current_monologue()) {
            $self->emit (name => 'tcp_monologue',
                         args =>{socketpair_key => $k,
                                 monologue      =>$sesh->current_monologue()});
        }

        $self->emit (name => 'tcp_session_end',
                     args => {socketpair_key => $k});
    }

    $self->trace ("======[--:--:--.------] TCP teardown") if ($self->{v} & 0x08);
}

# }}}

# {{{ _internal_tcp_packet

# _internal_tcp_packet: emits tcp_session_start, tcp_monologue, tcp_session_end

sub _internal_tcp_packet {
    my ($self, $args) = @_;
    my ($pkt) = $args->{pkt};

    my @events = (); # The carefully sequenced list of events

    # Get the TCP session key from the packet.
    my $k = $pkt->[PKT_SLOT_SOCKETPAIR_KEY];

    # Establish session object
    my $sesh = $self->_get_session_object($k);

    return if (($sesh->{total_bytes} >= $self->{max_session_size}) &&
              ($self->{max_session_size} > 0));

    # Feed it packet
    my $ret = $sesh->process_packet(packet => $pkt);
    #my $deb = "  = ". (($self->{v} & 0x08) ? $pkt->as_string(1) : "$pkt");

    # Maybe emit events ...
    if ($ret == PKT_ESTABLISHED_SESSION) {
        $self->_trace_pkt($pkt,$ret) if ($self->{v} & 0x01);
        push (@events, {name => 'tcp_session_start',
                        args => {socketpair_key => $k,
                                 pkt => $pkt} });

    } elsif ($ret == PKT_FLIPPED_DIR) {
        push (@events, {name => 'tcp_monologue',
                        args => {socketpair_key => $k,
                                 monologue => $sesh->previous_monologue()}});

        $self->_trace_pkt($pkt,$ret) if ($self->{v} & 0x01);

    } elsif ($ret == PKT_TERMINATED_SESSION) {
        $self->_trace_pkt($pkt) if ($self->{v} & 0x01);

        # Clear out any remaining data
        if ($sesh->has_current_monologue()) {
            push (@events, {name => 'tcp_monologue',
                            args =>{socketpair_key => $k,
                                    monologue =>$sesh->current_monologue()}});
        }

        # Now end the session nicely.
        push (@events, {name => 'tcp_session_end',
                        args => {socketpair_key => $k,
                                 pkt => $pkt}});
        $self->_close_down_session ($k);

    } else {
        $self->_trace_pkt($pkt,$ret) if ($self->{v} & 0x01 || $self->{k} eq $k);
    }

    unshift (@events, {name => 'tcp_packet', args => $args} );

    foreach (@events) {
        $self->emit( %{ $_ } );
    }
}

# }}}

# {{{ tcp_session_start

# Fairly pointless; we don't need to listen to this event, really.
sub tcp_session_start {
    my ($self, $args) = @_;
    my $pkt = $args->{pkt}; # Might well be undef
    my $k   = $args->{socketpair_key};

    if ($self->{v} & 0x04) {
        my $t = pkt_time($pkt)->as_string('time');
        $self->trace ("  ====[$t] tcp session start [".
                      $pkt->[PKT_SLOT_FROM]." -> ".
                      $pkt->[PKT_SLOT_TO]."]");
    }
}

# }}}
# {{{ tcp_session_end

# Fairly pointless; we don't need to listen to this event, really.
sub tcp_session_end {
    my ($self, $args) = @_;
    my $pkt = $args->{pkt}; # Might well be undef
    my $k   = $args->{socketpair_key};

    if ($self->{v} & 0x04) {
        my $t = $pkt ? pkt_time($pkt)->as_string('time') : '--:--:--.------';
        $self->trace("  ====[$t] tcp session end [$k]");
    }
}

# }}}
# {{{ tcp_monologue

# Fairly pointless; we don't need to listen to this event, really.
sub tcp_monologue {
    my ($self, $args) = @_;
    my $k    = $args->{socketpair_key};
    my $mono = $args->{monologue};

    $self->{_counters}{$k} ||= 0;
    $self->{_counters}{$k}++;

    if ($self->{v} & 0x02) {
        my $t = $mono->{time}->as_string('time');
        $self->trace(sprintf ("    ==[$t] $mono\n"));
    }

    if ($self->{dumps}) {
        my $fname = "$k.$self->{_counters}{$k}";
        if (open (MONO, ">$fname")) {
            print MONO $mono->{data};
            close (MONO);
        } else {
            warn ("open+w '$fname': $!\n");
        }
    }
}

# }}}

# {{{ as_string

sub as_string {
    my ($self) = @_;
    my $s = '';

    my $n = scalar (keys %{ $self->{active_tcp_sessions} });

    $s .= "[".ref($self)."], $n open sessions";

    return $s;
}

# }}}

#### Support funcs
#
# {{{ _get_session_object

sub _get_session_object {
    my ($self, $k) = @_;

    my ($sesh) = $self->{active_tcp_sessions}{$k} || undef;

    if (!defined $sesh) {
        $sesh = Net::Analysis::TCPSession->new();
        $self->{active_tcp_sessions}{$k} = $sesh;
    }

    return $sesh;
}

# }}}
# {{{ _close_down_session

sub _close_down_session {
    my ($self, $k) = @_;

    # XXXX Implement 2xMLS TIME_WAIT thing, ideally ...

    if ($self->{active_tcp_sessions}{$k}{rst}) {
        $self->{rsts}++;
    } else {
        $self->{non_rsts}++;
    }

    delete ($self->{active_tcp_sessions}{$k});
}

# }}}
# {{{ _trace_pkt

sub _trace_pkt {
    my ($self, $pkt, $str) = @_;
    my $deb = "  = ". (($self->{v} & 0x08)
                       ? pkt_as_string($pkt,1)
                       : pkt_as_string($pkt));

    $deb .= " '$str'" if (defined $str);

    $self->trace($deb);
}

# }}}

1;
__END__
# {{{ POD

=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::Analysis::Listener::Base
Net::Analysis::TCPSession
Net::Analysis::TCPMonologue

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}
