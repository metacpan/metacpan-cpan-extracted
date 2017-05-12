# $Id: Message.pm,v 1.9 2004/04/22 20:45:32 davidb Exp $
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

package Net::BEEP::Lite::Message;

=head1 NAME

Net::BEEP::Lite::Message

=head1 SYNOPSIS

  use Net::BEEP::Lite::Message;

  my $message = Net::BEEP::Lite::Message->new
   ( Frame => $frame );

  $message->add_frame($next_frame);

  my $message2 = new Net::BEEP::Lite::Message
   ( Type        => 'MSG',
     Channel     => 3,
     Content     => $content,
     ContentType => 'application/xml' );

  for my $frame ($message2->next_frame($seqno, $max_size)) {
    # ... send the frame
  }

=head1 DESCRIPTON

This class represents a BEEP message, the basic unit of data transport
at the user level.  It contains both a reference to the session that
it was received on (or will be sent by), and content.  It contains
methods to construct and deconstruct the message into frames, the
actual base unit of transport.

This class is expected to be used in user code by both clients and
servers.

=cut

use Carp;

use Net::BEEP::Lite::Frame;

use strict;
use warnings;

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This is the main constructor.  It takes a named parameter list as its
argument.  The following parameters are recognized:

=over 4

=item Session

A reference to the session that the message was received by or will be sent by.

=item Type

The message type (e.g., "MSG", "RPY", "ERR", etc.)

=item Msgno

The message number.  This is generally fetched from the session, or,
for replies, from the message being replied to.  This should only be
set for replies.  'MSG's should be set by the session on sending it.

=item Channel

The channel number.

=item Payload

The message payload (including the MIME header(s)).  Either this or
"Content" and "ContentType" MUST be supplied.

=item Content

The message content (not including the MIME headers).

=item ContentType

The message content type.  This will be added as a MIME header when
forming the payload.  If not supplied, the default content type is
'application/octet-stream'.

=item ContentEncoding

The content encoding.  This will be added as a MIME header when
forming the payload, if supplied.

=item Frame

A frame to form the basis (or entire) message.  Generally, this is
supplied on its own.

=item Debug

Emit debug messages.

=back

=back

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %args = @_;

  my $self = {};
  bless $self, $class;

  # ANSNO is only set for ANS message, but we would like it to be a
  # defined hash element in either case.
  $self->{ansno} = undef;

  $self->{debug} 		 = 0;
  $self->{trace}                 = 0;
  # this is used by next_frame()
  $self->{frame_offset} 	 = 0;
  $self->{generated_first_frame} = 0;

  $self->{payload} = $self->{content} = "";

  for (keys %args) {
    my $val = $args{$_};

    /^Type$/i and do {
      $self->type(uc $val);
      next;
    };
    /^Msgno$/i and do {
      $self->msgno($val);
      next;
    };
    /^Ansno$/i and do {
      $self->ansno($val);
      next;
    };
    /^Channel$/i and do {
      $self->{channel_number} = $val;
      next;
    };
    /^Payload$/i and do {
      $self->{payload} = $val;
      next;
    };
    /^Content$/i and do {
      $self->{content} = $val;
      next;
    };
    /^Content.?Type$/i and do {
      $self->{content_type} = $val;
      next;
    };
    /^Content.?Encoding$/i and do {
      $self->{content_encoding} = $val;
      next;
    };
    /^Frame$/i and do {
      $self->{type}   	      = $val->type();
      $self->{msgno} 	      = $val->msgno();
      $self->{ansno}          = $val->ansno();
      $self->{channel_number} = $val->channel_number();
      $self->{payload} 	      = $val->payload();
      next;
    };
    /^Debug$/i and do {
      $self->{debug} = $val;
      next;
    };
    /^Trace$/i and do {
      $self->{trace} = $val;
      next;
    };
  }

  $self;
}

=head1 METHODS

=over 4

=item type([$val])

Returns the type of the message (e.g., "MSG", "RPY", etc.).  Updates
the type to $val if provided.

=cut

sub type {
  my $self = shift;
  my $val  = shift;

  $self->{type} = $val if $val;
  $self->{type};
}

=item msgno([$val])

Returns (or sets) the message number of the message.

=cut

sub msgno {
  my $self = shift;
  my $val  = shift;

  $self->{msgno} = $val if defined $val;
  $self->{msgno};
}


sub ansno {
  my $self = shift;
  my $val = shift;

  $self->{ansno} = $val if defined $val;
  $self->{ansno};
}

=item size()

Returns the size of the payload of the message.

=cut

sub size {
  my $self = shift;

  length($self->payload());
}

=item channel_number([$va])

Returns or sets the channel number of the message.

=cut

sub channel_number {
  my $self = shift;
  my $val  = shift;

  $self->{channel_number} = $val if defined $val;
  $self->{channel_number};
}

=item payload()

Returns the payload of the message, forming it from the content,
content type, and content encoding, if necessary.

=cut

sub payload {
  my $self = shift;

  $self->_content_payload_transfer();
  $self->{payload};
}

=item content_type()

Returns the content type of the message (either set or parsed from the
payload).

=cut

sub content_type {
  my $self = shift;
  $self->_content_payload_transfer();

  $self->{content_type} || 'application/octet-stream';
}

=item content_encoding()

Returns the content encoding of the message (if one where set or
detected from the payload).

=cut

sub content_encoding {
  my $self = shift;
  $self->_content_payload_transfer();

  $self->{content_encoding} || 'binary';
}

=item content()

Returns the content of the message (the payload minus MIME headers).
It calculates the content from the payload, if necessary.

=cut

sub content {
  my $self = shift;
  $self->_content_payload_transfer();

  $self->{content};
}

=item _content_payload_transfer()

This will force the translation between content and payload.
Currently this can only be done once, but then again, this class
doesn't support changing either of them through the API.  If you do
so, be sure to set the other to undef so that this routine will work.

=cut

sub _content_payload_transfer {
  my $self = shift;

  if (! $self->{content} and $self->{payload}) {
    $self->_decode_mime();
  }
  elsif (! $self->{payload} and $self->{content}) {
    $self->_encode_mime();
  }
}

=item _decode_mime()

Parse the payload into content, content type, and content encoding.
This is normally called automatically.

=cut

sub _decode_mime {
  my $self = shift;

  my $payload = $self->{payload};

  my ($content, @headers) = _decode_mime_entity($payload);

  $self->{content} = $content;

  for my $header (@headers) {
    next if not $header =~ /^(\S+):\s*(\S.*$)/;
    if ($1 eq 'Content-Type') {
      $self->{content_type} = $2;
    } elsif ($1 eq 'Content-Transfer-Encoding') {
      $self->{content_encoding} = $2;
    }
  }
}

=item _encode_mime()

Calculate the payload from the set content, content type, and content
encoding.  This is normally called automatically.

=cut

sub _encode_mime {
  my $self = shift;

  my @headers;
  my $ct = $self->{content_type};
  if ($ct and $ct ne 'application/octet-stream') {
    push @headers, "Content-Type: $ct";
  }
  my $ce = $self->{content_encoding};
  if ($ce and $ce ne "binary") {
    push @headers, "Content-Transfer-Encoding: $ce";
  }

  my $payload = _encode_mime_entity($self->{content}, @headers);

  $self->{payload} = $payload;
}

=item add_frame($frame)

Add a frame to an existing message.  This is used to assemble a
message from multiple frames.  For now, this method doesn't really
check that the additional frames really belong to the message.

=cut

sub add_frame {
  my $self  = shift;
  my $frame = shift;
  # TODO: check to see if this frame matches the message.

  if (!$self->{payload} and $self->{content}) {
    $self->payload();  # force the payload to be constructed.
  }
  # we want to force the content to be constructed from the payload
  # after this.
  $self->{content} = undef;

  my ($content, @headers) = _decode_mime_entity($frame->payload());
  $self->{payload} .= $content if $content;
}

=item has_more_frames()

Return true if there are more frames to be generated from this message.

=cut

sub has_more_frames {
  my $self = shift;

  return 1 if not $self->{generated_first_frame};

  my $remainder = length($self->payload()) - $self->{frame_offset};

  $remainder > 0 ? 1 : 0;
}

=item next_frame($seqno, $max_size)

Returns the "next" frame in the message, based on given maximum size.
This method will split the message into multiple frames if the maximum
size forces it to.  This will return undef when the entire message has
been rendered into frames.  See the reset_frames() method if you wish
to convert the same message into frames multiple times.

=cut

sub next_frame {
  my $self     = shift;
  my $seqno    = shift;
  my $max_size = shift;

  my $chno = $self->channel_number();

  confess "msgno was not set before next_frame()"
    if (not defined $self->msgno());

  croak "maximum size of zero for message: type = ", $self->type(),
    " msgno = ", $self->msgno(), " chno = $chno\n" if $max_size == 0;

  my $payload = $self->payload();
  my $remainder = length($payload) - $self->{frame_offset};

  return undef if ($self->{generated_first_frame} and $remainder <= 0);

  $self->{generated_first_frame} = 1;

  my $more;
  my $local_payload;

  if ($remainder > $max_size) {
    print STDERR "***** fragmenting message.\n" if $self->{debug};
    $local_payload = substr($payload, $self->{frame_offset}, $max_size);
    $more = '*';
  } else {
    $local_payload = substr($payload, $self->{frame_offset});
    $more = '.';
  }

  my $frame =  Net::BEEP::Lite::Frame->new
    (Type    => $self->type(),
     Msgno   => $self->msgno(),
     Ansno   => $self->ansno(),
     More    => $more,
     Seqno   => $seqno,
     Channel => $self->channel_number(),
     Payload => $local_payload);

  $self->{frame_offset} += length($local_payload);

  $frame;
}

=item reset_frames()

This will reset the counter used by next_frame().  Use this if you want
to start calculating frames from the beginning more than once.

=cut

sub reset_frames {
  my $self = shift;

  $self->{frame_offset} 	 = 0;
  $self->{generated_first_frame} = 0;
}

sub _decode_mime_entity {
  my $block = shift;

  my @headers;

  # FIXME: this routine really sucks.  We need to find a more reliable
  # method.

  # first make sure that this looks like a MIME message at all:
  if (not $block or not $block =~ /^Content-Type:/im) {
    return ($block, @headers);
  }

  my @lines = split(/\r\n/, $block);
  while (1) {
    my $line = shift @lines;
    chomp $line;
    last if not $line;
    push @headers, $line;
  }

  my $content = join("\r\n", @lines);

  ($content, @headers);
}

sub _encode_mime_entity {
  my $content = shift;
  my @headers = @_;

  return $content if (not @headers);

  my $res = "";
  for my $header (@headers) {
    chomp $header;
    $res .= $header . "\r\n";
  }
  $res .= "\r\n";
  $res .= $content;

  $res;
}

=pod

=back

=head1 SEE ALSO

=over 4

=item L<Net::BEEP::Lite::Session>

=item L<Net::BEEP::Lite::Frame>

=back

=cut

1;
