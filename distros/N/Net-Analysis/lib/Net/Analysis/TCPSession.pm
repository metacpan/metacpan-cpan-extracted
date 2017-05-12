package Net::Analysis::TCPSession;
# $Id: TCPSession.pm 131 2005-10-02 17:24:31Z abworrall $

# {{{ Boilerplate

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @PKT_CONSTS  = qw(PKT_REJECTED
                      PKT_OK
                      PKT_ESTABLISHED_SESSION
                      PKT_FLIPPED_DIR
                      PKT_TERMINATED_SESSION
                      );

our @EXPORT      = qw();
our @EXPORT_OK   = (@PKT_CONSTS);
our %EXPORT_TAGS = (all    => [ @EXPORT, @EXPORT_OK ],
                    const  => [ @PKT_CONSTS ]);

# }}}

use overload q("") => sub { $_[0]->as_string() }; # OO style stringify
use Carp qw(carp croak confess);
use Params::Validate qw(:all);

use Net::Analysis::Constants qw(:packetclasses);
use Net::Analysis::Packet qw(:all);
use Net::Analysis::TCPMonologue;

# {{{ Constants & globals

use Net::Analysis::Constants qw(:all);

# Return codes for process_packet(); notify of state change.
use constant {
    # Return codes for process_packet();
    PKT_REJECTED            => 0, # Never used !
    PKT_OK                  => 1, # Packet absorbed happily
    PKT_ESTABLISHED_SESSION => 2, # Data packets about to flow
    PKT_FLIPPED_DIR         => 3, # Change of direction in data flow
    PKT_TERMINATED_SESSION  => 4, # Should have been last packet
};


our $TRACE = 0; # Override via local() for per-subroutine debugging via _trace

# }}}

#### Public methods
#
# {{{ new

sub new {
    my ($class) = shift;

    my %h = validate (@_, {});

    my ($self) = bless ({}, $class);

    $self->_init (\%h);

    return $self;
}

# }}}

# {{{ process_packet

sub process_packet {
    my $self = shift;

    my %h = @_;
#    my %h = validate (@_, {packet  => { type  => HASHREF } });

    $self->_clear_status_change();

    # Look for SYN/FINs, check ACKs etc
    $self->_update_status ($h{packet});

    # Does this packet have data ? If not, skip it
    if (! length($h{packet}[PKT_SLOT_DATA])) {
        #$self->_trace ("  -- no data in packet, skipping\n");
        pkt_class ($h{packet}, PKT_NONDATA);
        return $self->_determine_status_change();
    }

    #$self->_trace ("---- new pkt: $h{packet}");

    # Orient ourselves, if necessary
    $self->_setup_session ($h{packet}) if (! exists $self->{to});

    # Eat (or discard, or store) this packet.
    $self->_consume_data_packet ($h{packet});

    # Decide what this packet has done to the status of our stream
    my $ret = $self->_determine_status_change();

    # If we can, process any packets we've got stored in this dir
    # XXXX But what if these packets also cause state changes ??
    $self->_process_stored_packets($h{packet}[PKT_SLOT_FROM]);

    return $ret;
}

# }}}

# {{{ previous_monologue

sub previous_monologue {
    my $self = shift;

    return $self->{previous_monologue};
}

# }}}
# {{{ current_monologue

sub current_monologue {
    my $self = shift;

    return $self->{current_monologue};
}

# }}}
# {{{ has_current_monologue

sub has_current_monologue {
    my $self = shift;

    return (defined $self->{current_monologue});
}

# }}}
# {{{ status

sub status {
    my ($self, $status) = @_;

    if (defined $status) {
        # Remember what we were, so we can determine what changed later
        $self->{_prev_status} = $self->{status};
        $self->{status} = $status;
    }

    return $self->{status};
}

# }}}

# {{{ errstr

sub errstr {
    my ($self, $msg) = @_;

    $self->{errstr} = $msg if (defined $msg);

    return $self->{errstr};
}

# }}}

# {{{ as_string

sub as_string {
    my ($self) = @_;
    my $s = '';

    $s .= "[".ref($self)." $self->{total_bytes} bytes] ".$self->status();

    return $s;
}

# }}}


#### Private helper methods
#
# {{{ _init

sub _init {
    my ($self, $h) = @_;

    $self->{errstr}             = '';
    $self->{previous_monologue} = $self->{current_monologue} = undef;
    $self->{future_packets}     = {};
    $self->{status}             = SESH_UNDEFINED;
    $self->{total_bytes}        = 0;
    $self->{_syn_fins}          = {};
}

# }}}
# {{{ _trace

# This may become more clever ...

sub _trace {
    my ($self) = shift;

    return if (! $TRACE);

    foreach (@_) {
        my $l = $_; #  Skip 'Modification of a read-only value' errors
        chomp ($l);
        print "$l\n";
    }
}

# }}}

# {{{ _update_status

# Look for ACKed SYNs and FINs.

sub _update_status {
    my ($self, $pkt) = @_;

    # Basic counters
    $self->{n_pkts}++;
    $self->{bytes_from}{$pkt->[PKT_SLOT_FROM]} +=
        length($pkt->[PKT_SLOT_DATA]);

    #local $TRACE = 1;

    # This hash maps sequence numbers to unACKed SYN/FIN packets
    my ($h) = $self->{_syn_fins};

    if ($pkt->[PKT_SLOT_FLAGS] & ACK) {
        # Does it ACK an open SYN or FIN ? Change state if necessary
        my $acked_pkt = delete ($h->{$pkt->[PKT_SLOT_ACKNUM] - 1});
        if (defined $acked_pkt) {
            #$self->_trace ("-- update_status: good ACK    : $pkt");
            #$self->_trace (" - (acked thing was           : $acked_pkt)");

            if ($acked_pkt->[PKT_SLOT_FLAGS] & SYN) {
                if (++$h->{acked_syns} < 2) { $self->status (SESH_CONNECTING) }
                else                        { $self->status (SESH_ESTABLISHED)}
            } elsif ($acked_pkt->[PKT_SLOT_FLAGS] & FIN) {
                if (++$h->{acked_fins} < 2) { $self->status (SESH_HALF_CLOSED)}
                else                        { $self->status (SESH_CLOSED)     }
            }
        }
    }

    if ($pkt->[PKT_SLOT_FLAGS] & (SYN|FIN)) {
        # Open a new SYN/FIN (or discard)
        if (! exists ($h->{$pkt->[PKT_SLOT_SEQNUM]})) {
            #$self->_trace ("-- update_status: new SYN/FIN : $pkt");
            # Be aware that a FIN packet may also contain data ...
            $h->{$pkt->[PKT_SLOT_SEQNUM]+ length $pkt->[PKT_SLOT_DATA]} = $pkt;
        } else {
            #$self->_trace ("-- update_status: dup SYN/FIN : $pkt");
        }
    }

    if ($pkt->[PKT_SLOT_FLAGS] & RST) {
        # If the session is being RESET, close it down.
        # $self->_trace ("-- update_status: RST         : $pkt");
        $self->status (SESH_CLOSED);
    }

    # If we are currently undefined, presumably because we've started looking
    #  at an already established session, have a guess of where we should be
    #  based on this packet
    if ($self->status() eq SESH_UNDEFINED) {
        if (length($pkt->[PKT_SLOT_DATA]))   {$self->status(SESH_ESTABLISHED)}
        elsif ($pkt->[PKT_SLOT_FLAGS] & SYN) {$self->status(SESH_CONNECTING) }
    }
}

# }}}
# {{{ _setup_session

sub _setup_session {
    my ($self, $pkt) = @_;

    # Use this packet pick a to/from orientation for the rest of the session.
    $self->{to}      = $pkt->[PKT_SLOT_TO];
    $self->{from}    = $pkt->[PKT_SLOT_FROM];
    $self->{tv_usec} = $pkt->[PKT_SLOT_TV_USEC];
    $self->{tv_sec}  = $pkt->[PKT_SLOT_TV_SEC];

    my ($from,$to) = ($self->{from}, $self->{to});

    # Initialise the TCP stream sequence numbers in both directions
    $self->{$from}{seq} = $pkt->[PKT_SLOT_SEQNUM];
    $self->{$to}  {seq} = $pkt->[PKT_SLOT_ACKNUM]; # Assume the ack is relevent

    # Now set things up so that we are 'expecting' this packet.
    # Pretend we are already going in this diretion, to avoid FLIPPED_DIR
    $self->{last_from} = $from;

    # Setup the first monologue
    $self->{current_monologue} = Net::Analysis::TCPMonologue->new();
}

# }}}
# {{{ _flip_if_necessary

sub _flip_if_necessary {
    my ($self, $pkt) = @_;

    # New packet same direction as the old one ? No change !
    return if ($pkt->[PKT_SLOT_FROM] eq $self->{last_from});

    # Else, all change !!
    #$self->_trace ("  -- packet FLIPS direction !\n");

    # Store the now finished monologue for later retrieval
    $self->{previous_monologue} = $self->{current_monologue};

    # New monologue
    $self->{current_monologue} = Net::Analysis::TCPMonologue->new();

    $self->{last_from} = $pkt->[PKT_SLOT_FROM];

    # Make a note, so we know what this packet did
    $self->_set_flip_status();
}

# }}}
# {{{ _consume_data_packet

sub _consume_data_packet {
    my ($self, $pkt) = @_;
    my $pf = $pkt->[PKT_SLOT_FROM];
    #our $TRACE = 1;

    $self->{total_bytes} += length($pkt->[PKT_SLOT_DATA]);

    # Check to see where packet slots into the TCP datastream.
    if ($pkt->[PKT_SLOT_SEQNUM] == $self->{$pf}{seq}) {
        #$self->_trace ("  -- pkt seq agrees with what we expected (inc by ".
        #               length($pkt->{data}).")");

        # If traffic has changed direction, store monologue.
        $self->_flip_if_necessary($pkt);

        # Only add pkt _after_ flip detection, to preserve previous monologue
        $self->{current_monologue}->add_packet ($pkt);

        # Update the seq counter - we've eaten this data now
        $self->{$pf}{seq} += length($pkt->[PKT_SLOT_DATA]);

        # We might be re-processing a stored packet, in which preserve its
        #  value
        pkt_class ($pkt, PKT_DATA) if (pkt_class($pkt) == PKT_NOCLASS);

    } elsif ($pkt->[PKT_SLOT_SEQNUM] > $self->{$pf}{seq}) {
        #$self->_trace ("  -- * packet is ".($pkt->{seqnum}-$self->{$pf}{seq}).
        #               " bytes into the future; storing for later");
        $self->_store_future_packet ($pkt);

        pkt_class ($pkt, PKT_FUTURE_DATA);

    } else {
        #$self->_trace ("  -- ** packet is ".($self->{$pf}{seq}-$pkt->{seqnum}).
        #               " bytes into the past; discarding");
        pkt_class ($pkt, PKT_DUP_DATA);
    }
}

# }}}

# {{{ _store_future_packet

sub _store_future_packet {
    my ($self, $pkt) = @_;

    $self->{future_packets}{$pkt->[PKT_SLOT_FROM]}{$pkt->[PKT_SLOT_SEQNUM]} = $pkt;
}

# }}}
# {{{ _process_stored_packets

sub _process_stored_packets {
    my ($self, $dir) = @_;

    # Check that we have some stored packets in our current direction
    return if (! exists $self->{future_packets}{$dir});

    while (1) {
        my $pkt = delete $self->{future_packets}{$dir}{$self->{$dir}{seq}};
        last if (!defined $pkt);

        #$self->_trace ("  -- found future bytes: $self->{$dir}{seq}+".
        #               length($pkt->{data}));

        # Ignore return value; can't flip, since $dir is fixed
        $self->_consume_data_packet ($pkt);
    }
}

# }}}

# Routines related to handling changes in session status
# {{{ _clear_status_change

sub _clear_status_change {
    my ($self) = @_;
    $self->{_prev_status} = $self->{status};
    $self->{_have_flipped} = 0;
}

# }}}
# {{{ _set_flip_status

sub _set_flip_status {
    my ($self) = @_;
    $self->{_have_flipped} = 1;
}

# }}}
# {{{ _determine_status_change

sub _determine_status_change {
    my ($self) = @_;
    my ($prev) = $self->{_prev_status};

    # Flipped takes precedence.
    return PKT_FLIPPED_DIR if ($self->{_have_flipped});

    if (defined $prev && $prev ne $self->{status}) {
        # So, we have changed state, to $s. Decide what to return.
        # We don't use =>, since it will single quote our constants !
        my (%chngs) = (SESH_UNDEFINED  , PKT_REJECTED, # Error !!
                       SESH_CONNECTING , PKT_OK,
                       SESH_ESTABLISHED, PKT_ESTABLISHED_SESSION,
                       SESH_HALF_CLOSED, PKT_OK,
                       SESH_CLOSED     , PKT_TERMINATED_SESSION,
                      );

        die "(prev=$prev, st=$self->{status}: change *AND* flip\n" if ($self->{_have_flipped});

        return $chngs{$self->{status}};
    }

    return ($self->{_have_flipped} ? PKT_FLIPPED_DIR : PKT_OK);
}

# }}}

1;
__END__
# {{{ POD

=head1 NAME

Net::Analysis::TCPSession - represent a TCP session (with two endpoints)

=head1 SYNOPSIS

  use Net::Analysis::TCPSession qw(:const);

  my $sesh = Net::Analysis::TCPSession->new ();

  foreach my $pkt (@packets) {
    my $ret = $sesh->process_packet ($pkt);
    ($ret) || die "broken session: ".$sesh->errstr();
    print " >> $sesh <<\n";

    if      ($ret == PKT_ESTABLISHED_SESSION) {
      print "new session established\n";

    } elsif ($ret == PKT_TERMINATED_SESSION) {
      print "session torn down\n";

    } elsif ($ret == PKT_FLIPPED_DIR) {
      print "monologue generated\n----\n".$sesh->previous_monologue();
    }
  }

  if ($sesh->has_current_monologue()) {
    print "final monologue\n----\n".$sesh->current_monologue();
  }

=head1 DESCRIPTION

Processes a packet in the context of an existing TCP session. This is the
module that does the bulk of the stream management; SYNs, ACKs, dropping
duplicates and storing out-of-sequence packets.

A packet, once placed in order, is considered to do just one of four things:

=over 4

=item *

establish a new TCP session

=item *

add data to a TCP monologue (data travelling in one direction)

=item *

flip the direction of conversation (thus terminating existing monologue)

=item *

terminate the TCP session

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

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
