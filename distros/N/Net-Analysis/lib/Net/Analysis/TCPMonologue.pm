package Net::Analysis::TCPMonologue;
# $Id: TCPMonologue.pm 136 2005-10-21 00:14:54Z abworrall $

use 5.008000;
our $VERSION = '0.02';
use strict;
use warnings;

use overload
    q("") => sub { $_[0]->as_string() },
    'eq'  => sub { return "$_[0]" eq "$_[1]" }; # Needed for Test::is_deeply

use Carp qw(carp croak confess);
use Params::Validate qw(:all);

use Net::Analysis::Packet qw(:all);

# {{{ POD

=head1 NAME

Net::Analysis::TCPMonologue - simple class to contain a TCP monologue

=head1 SYNOPSIS

  use Net::Analysis::Packet;
  use Net::Analysis::Monologue;

  my $mono = Net::Analysis::Monologue->new();
  $mono->add_packet($pkt);

  if ($mono->data() =~ /foo/) {
    print "Mono contained 'foo'\n";
  }

  print "Monologue was " .$mono->length().
        "b long, over "  .$mono->t_elapsed ()." seconds\n";

=head1 DESCRIPTION

A TCP monologue is a series of packets that travel in one direction, e.g. a
HTTP response. A monologue ends when a data packet travels in the other
direction. Pairs of monologues will often be linked as transactions.

As packets are added, this object updates some info. It assumes that the packet
you've added belongs in the monologue, and that you're adding them in the
correct order.

The payload of the monologue lives in C<$mono->{data}>.

=head1 METHODS

=cut

# }}}

#### Public methods
#
# {{{ new

# {{{ POD

=head2 new ( )

Takes no arguments.

=cut

# }}}

sub new {
    my ($class) = shift;

    my %h; # = validate (@_, {});

    my ($self) = bless ({}, $class);

    return $self;
}

# }}}
# {{{ add_packet

=head2 add_packet ($pkt)

Adds any data, increments the packet counter, and keeps note of the time.

=cut

sub add_packet {
    my ($self, $pkt) = @_;

    if (!exists $self->{data}) {
        # No data ? Must be the first packet; trigger some init
        $self->_init_from_first_packet($pkt);
    }

    # Keep track of which packets crontibuted which bytes
    push (@{$self->{which_pkts}}, [length($self->{data}), $pkt]);

    $self->{n_packets}++;
    $self->{data} .= $pkt->[PKT_SLOT_DATA];

    # Now update the 'last packet' time counters
    if (pkt_time($pkt) > $self->{time}) {
        $self->{time}  = pkt_time($pkt);
    }

    #print "Adding packet $pkt to $self\n";

    return 1;
}

# }}}
# {{{ add_mono

=head2 add_mono ($other_mono)

Walks through the packets in C<$other_mono>, and adds each one to C<$self>.

=cut

sub add_mono {
    my ($self) = shift;
    my ($other_mono) = @_;

    foreach my $pkt (@{ $other_mono->_data_packets }) {
        $self->add_packet ($pkt);
    }
}

# }}}
# {{{ data

=head2 data ()

The actual data of the monologue; the bytes sent.

=cut

sub data {
    my ($self) = @_;
    return $self->{data};
}

# }}}

# {{{ t_start

=head2 t_start ()

Returns an object representing the time the monologue started. Can be treated
like a float, giving fractional epoch seconds. Only accurate to the
microsecond.

=cut

sub t_start {
    my ($self) = @_;
    return $self->{t_start};
}

# }}}
# {{{ t_end

=head2 t_end ()

Same as C<t_start()>, but giving the time the monologue ended (or the last
packet so far, if you call it before the monologue has ended.)

=cut

sub t_end {
    my ($self) = @_;
    return $self->{time};
}

# }}}
# {{{ t_elapsed

=head2 t_elapsed ()

Returns an object representing C<t_end - t_start> for this monologue. Can be
treated like a float, giving duration in fractional seconds.

=cut

sub t_elapsed {
    my ($self) = @_;
    return ($self->{time} - $self->{t_start});
}

# }}}
# {{{ n_packets

=head2 n_packets ()

How many data packets were in the monologue.

=cut

sub n_packets {
    my ($self) = @_;
    return ($self->{n_packets});
}

# }}}
# {{{ length

=head2 length ()

How long the monologue data was, in bytes. Excludes all the various packet
headers.

=cut

sub length {
    my ($self) = @_;
    return length($self->{data});
}

# }}}
# {{{ first_packet

=head2 first_packet ()

Returns the first L<Net::Analysis::Packet> in the monologue. You can use it to
extract any TCP or IP information about the monologue.

=cut

sub first_packet {
    my ($self) = @_;
    return $self->{first_packet};
}

# }}}
# {{{ which_pkt

# Deprecated; use which_pkts instead

sub which_pkt {
    my ($self, $n) = @_;
    return $self->which_pkts($n)->[0];
}

# }}}
# {{{ which_pkts

=head2 which_pkts ($byte_offset_start [, $byte_offset_end])

Given a byte offset from within the monologue, and optionally an
offset later in the monologue, return the packets which contributed
bytes between the offsets (or an empty arrayref if none found). Bytes
are counted from zero (i.e. offset '0' would be the first byte).

This can be useful to retrieve timestamps of areas inside long-lived
monologues.

=cut

sub which_pkts {
    my ($self, $in_s, $in_e) = @_;

    $in_e ||= $in_s;
    die "bad args to which_pkts; end < start" if ($in_e < $in_s);

    return [] if ($in_s < 0 || $in_s >= CORE::length($self->{data}));

    my @ret;
    for my $row (@{ $self->{which_pkts} }) {
        my ($pkt_s, $pkt) = @$row;
        my ($pkt_e) = $pkt_s + CORE::length($pkt->[PKT_SLOT_DATA]) - 1;

        # If our desired range can't overlap, go to next
        next if ($in_e < $pkt_s || $in_s > $pkt_e);
        push (@ret, $pkt);
    }

    return \@ret;
}

# }}}
# {{{ socketpair_key

=head2 socketpair_key ()

Returns the socketpair key of the TCP session containing the
monologue.

=cut

sub socketpair_key {
    my ($self) = @_;
    $self->{socketpair_key};
}

# }}}

# {{{ as_string

sub as_string {
    my ($self) = @_;
    my $str = '';

    if (exists $self->{data}) {
        my $dur = $self->t_elapsed();
        $str .= sprintf ("[Mono from %21.21s]%10.06fs, %3dpkts, %6db",
                         $self->{from}, $dur, $self->n_packets(),
                         $self->length());
    } else {
        $str .= "[Mono undefined]";
    }

    return $str;
}

# }}}

# {{{ _data_packets

=head2 _data_packets ()

Returns an array-ref, containing all the packets which contributed data to
the monologue.

NOTE: this method may go away sometime.

=cut

sub _data_packets {
    my ($self, $n) = @_;

    my @ret = map {$_->[1]} @{ $self->{which_pkts} };

    return \@ret;
}

# }}}

#### Private helper methods
#
# {{{ _init_from_first_packet

sub _init_from_first_packet {
    my ($self, $pkt) = @_;

    $self->{n_packets}      = 0;
    $self->{data}           = '';

    $self->{socketpair_key} = $pkt->[PKT_SLOT_SOCKETPAIR_KEY];
    $self->{to}             = $pkt->[PKT_SLOT_TO];
    $self->{from}           = $pkt->[PKT_SLOT_FROM];
    $self->{time}           = pkt_time($pkt) + 0; # Make a cloned copy

    # Keep copies of the first noted time, and the packet itself
    $self->{t_start}        = $self->{time};
    $self->{first_packet}   = $pkt;

    # Keep track of which packets contributed which bytes
    $self->{which_pkts}     = [];
}

# }}}

1;
__END__
# {{{ POD

=head2 EXPORT

None by default.

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
