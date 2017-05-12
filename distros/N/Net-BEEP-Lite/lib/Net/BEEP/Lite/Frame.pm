# $Id: Frame.pm,v 1.8 2004/03/29 19:02:37 davidb Exp $
#
# Copyright (C) 2003 Verisign, Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

package Net::BEEP::Lite::Frame;

=head1 NAME

Net::BEEP::Lite::Frame

=head1 SYNOPSIS

  my $frame1 = Net::BEEP::Lite::Frame->new
   (Header => $header,
    Payload => $payload);

  my $frame2 = Net::BEEP::Lite::Frame->new
   (Buffer => $header_plus_payload);

  my $frame3 = Net::BEEP::Lite::Frame->new
   (Type => "MSG",
    Msgno => $message_number,
    Size => $size,
    More => '.',
    Seqno => $sequence_number,
    Channel => $channel_number);

=head1 DESCRIPTION

"Net::BEEP::Lite::Frame" is a class used for describing BEEP frames, the
underlying unit of transport in BEEP.  This is generally not used in
user code.  Instead, it is used internally by the
C<Net::BEEP::Lite::Session> class for sending and receiving messages.

=cut

use Carp;

use strict;
use warnings;

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This is the main constructor for the class.  It takes a named argument list.  The following arguments are supported:

=over 4

=item Header

An unparsed frame header (e.g, "MSG 1 23 . 15563 49")

=item Payload

The frame payload (the frame minus the header and trailer).

=item Type

The frame type: one of (MSG, RPY, ERR, ANS, NUL, SEQ).

=item Msgno

The frame's message number.

=item Size

The size of the payload (not including trailer)

=item More

Either "." (no more), or "*" (more).  This is a flag that indicates
whether the message being described by this frame is complete.

=item Seqno

The sequence number of this frame.  This is generally the number of
octets already seen on the given channel.

=item Channel

The channel number.

=back

=back

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %args = @_;

  my $self = {};
  bless $self, $class;

  # set some defaults
  $self->{more}  = '.';
  $self->{size}  = 0;
  $self->{seqno} = 0;

  for (keys %args) {
    my $val = $args{$_};

    /^Header/i and do {
      $self->_parse_header($val);
      next;
    };
    /^Payload/i and do {
      $self->set_payload($val);
    };
    /^Type/i and do {
      $self->{type} = uc $val;
      next;
    };
    /^Msgno/i and do {
      $self->{msgno} = $val;
      next;
    };
    /^More/i and do {
      $self->{more} = $val;
      next;
    };
    /^Seqno/i and do {
      $self->{seqno} = $val;
      next;
    };
    /^Ansno/i and do {
      $self->{ansno} = $val;
      next;
    };
    /^Ackno/i and do {
      $self->{ackno} = $val;
      next;
    };
    /^Window/i and do {
      $self->{window} = $val;
      next;
    };
    /^Channel/i and do {
      # FIXME: this might be a channel object, if we had defined one.
      # For now we have to assume that it is a number (generally, 0 or
      # 1 in this implementation.)
      $self->{channel_number} = $val;
      next;
    };
    /^Payload/i and do {
      $self->set_payload($val);
      next;
    };
  }


  $self;
}

=head1 METHODS

=over 4

=item type()

Returns the type of the frame. (e.g., "MSG", "RPY, "SEQ", etc.).

=cut

sub type {
  my $self = shift;
  $self->{type};
}

=item msgno()

Returns the message number of the frame.

=cut

sub msgno {
  my $self = shift;
  $self->{msgno};
}

=item size()

Returns the size of the frame.  If there is a payload, it will return
the size of that.  In the absence of a payload, it will whatever it
has been set to (presumably by parsing a frame header).

=cut

sub size {
  my $self = shift;
  return length($self->payload()) if ($self->payload());
  $self->{size};
}

=item more()

Returns either "." (no more) or "*" (more), a flag indicating whether
or not this frame completes the message.

=cut

sub more {
  my $self = shift;
  $self->{more};
}

=item completes()

Return true if this is a completing frame.  I.e., return true if
the more field is ".".

=cut

sub completes {
  my $self = shift;

  $self->{more} eq '.' ? 1 : 0;
}


=item seqno()

Returns the sequence number of the frame.

=cut

sub seqno {
  my $self = shift;
  $self->{seqno};
}

=item ansno()

Returns the answer number.  This only has meaning for ANS frames.

=cut

sub ansno {
  my $self = shift;
  $self->{ansno};
}

=item channel_number()

Returns the channel number of the frame.

=cut

sub channel_number {
  my $self = shift;
  $self->{channel_number};
}

=item payload()

Return the payload of the frame.

=cut

sub payload {
  my $self = shift;
  $self->{payload};
}

=item ackno()

Returns the acknowledgment number of the frame.  (SEQ frames only).

=cut

sub ackno {
  my $self = shift;
  $self->{ackno};
}

=item window()

Returns the window size advertised by the frame. (SEQ frames only).

=cut

sub window {
  my $self = shift;
  $self->{window};
}

=item set_payload($payload)

Sets this frame's payload to $payload.

=cut

sub set_payload {
  my $self = shift;
  my $payload = shift;

  $self->{payload} = $payload;
}

sub _parse_header {
  my $self   = shift;
  my $header = shift;

  if (not $header) {
    die "*** data frame header malformed: empty header encountered\n";
  }

  #DEBUG
  # print "frame header: $header";

  my @fields = split(/\s+/, $header);

  $self->{type} = shift @fields;

  if (! defined $self->{type}) {
     # FIXME: should we die here?  For now, it seems good.
     die "*** data frame header malformed: type undefined\n";
  } elsif ($self->{type} eq "SEQ") {
    $self->{channel_number} = shift @fields;
    $self->{ackno} 	    = shift @fields;
    $self->{window} 	    = shift @fields;
  } else {
    if (scalar @fields != 5 and scalar @fields != 6) {
      # FIXME: should we die here?  For now, it seems good.
      # Mis-parsing a header means we are probably hopelessly lost in
      # the stream, or the peer is sending garbage.
      die "*** data frame header malformed: ", scalar @fields,
	" fields instead of 5 (or 6 for ANS): '$header'\n";
    }

    $self->{channel_number} = shift @fields;
    $self->{msgno} 	    = shift @fields;
    $self->{more} 	    = shift @fields;
    $self->{seqno} 	    = shift @fields;
    $self->{size} 	    = shift @fields;

    $self->{ansno} = shift @fields if ($self->type() eq 'ANS');
  }
}

sub _check_frame {
  my $self = shift;

  my $type = $self->type();
  return 0 if not $type =~ /^(SEQ|MSG|RPY|ERR|ANS|NUL)$/;
  return 0 if not defined $self->channel_number();
  if ($type eq 'SEQ') {
    return 0 if not defined $self->ackno();
    return 0 if not defined $self->window();
    return 1;
  }

  return 0 if not defined $self->msgno();
  return 0 if not $self->more();
  return 0 if not defined $self->seqno();
  return 0 if not defined $self->size();
  return 0 if $type eq 'ANS' and not defined $self->ansno();
}


=item header_to_string()

Returns the string form of the header.  This is valid for the wire.

=cut

sub header_to_string {
  my $self = shift;

  my $res = "";

  $res .= $self->type() . " " . $self->channel_number();
  if ($self->type() eq "SEQ") {
    $res .= " " . $self->ackno() . " " . $self->window();
  }
  else {
    $res .= " " . $self->msgno() . " " . $self->more() . " " .
      $self->seqno() . " " . $self->size();
    $res .= " " . $self->ansno() if $self->type() eq "ANS";
  }

  $res .= "\r\n";

  $res;
}

=item to_string()

Returns the string form of the entire frame (header, payload, and
trailer).  This valid for the wire.

=cut

sub to_string {
  my $self = shift;

  my $res = $self->header_to_string();
  if ($self->payload() and $self->type() ne 'NUL' and
      $self->type() ne 'SEQ') {
    $res .= $self->payload() . "END\r\n";
  }

  $res;
}

=pod

=back

=head1 SEE ALSO

=over 4

=item L<Net::BEEP::Lite::Session>

=back

=cut

1;
