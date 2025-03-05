############################################################################
# WebSocket support
############################################################################

use strict;
use warnings;
package Net::Inspect::L7::HTTP::WebSocket;
use Scalar::Util 'weaken';
use Carp 'croak';
use Digest::SHA 'sha1_base64';

sub upgrade_websocket {
    my ($self,$conn,$req,$rsp) = @_;

    # Websocket: RFC6455, Sec.4.1 Page 16ff
    my $wskey = $req->{fields}{'sec-websocket-key'} || [];
    if (@$wskey > 1) {
	my %x;
	$wskey = [ map { $x{$_}++ ? ():($_) } @$wskey ];
    }

    # Check request
    die "no sec-websocket-key given in request" if ! @$wskey;
    die "multiple sec-websocket-key given in request" if @$wskey > 1;
    die "method must be GET but is $req->{method}"
	if $req->{method} ne 'GET';
    my $v = $req->{fields}{'sec-websocket-version'};
    die "no sec-websocket-version field in request" if !$v;
    die "sec-websocket-version must be 13 not '@$v'"
	if grep { $_ ne '13' } @$v;

    # Check response
    my $wsa = $rsp->{fields}{'sec-websocket-accept'};
    if (@$wsa > 1) {
	my %x;
	$wsa = [ map { $x{$_}++ ? ():($_) } @$wsa ];
    }
    die "no sec-websocket-accept given in response" if ! @$wsa;
    die "multiple sec-websocket-accept given in response" if @$wsa > 1;

    # Check that sec-websocket-accept in response matches sec-websocket-key.
    # Beware its magic! see RFC6455 page 7.
    # sha1_base64 does no padding, so we need to add a single '=' (pad to 4*7
    # byte) at the end for comparison.
    if ( @$wsa != 1 or $wsa->[0] ne sha1_base64(
	$wskey->[0].'258EAFA5-E914-47DA-95CA-C5AB0DC85B11').'=') {
	die "sec-websocket-accept does not match sec-websocket-key";
    }


    my @sub;
    weaken($self);
    weaken($conn);
    for my $dir (0,1) {
	my $dir = $dir; # old $dir is only alias
	my $rbuf = '';

	# If $clen is defined we are inside a frame ($current_frame).
	# If $clen is not defined all other variables here do not matter.
	# Since control messages might be in-between fragmented data messages we
	# need to keep this information for an open data message.
	my ($clen,$clenhi,$current_frame,$data_frame,$ctl_frame,$got_close);

	$sub[$dir] = sub {
	    my ($data,$eof,$time) = @_;
	    my $err;

	    # Handle data gaps. These are only allowed inside data frames.
	    ############################################################
	    if (ref($data)) {
		croak "unknown type $data->[0]" if $data->[0] ne 'gap';
		my $gap = $data->[1];
		if (!defined $clen) {
		    $err = "gap outside websocket frame";
		    goto bad;
		}
		if (!$data_frame || $current_frame != $data_frame) {
		    $err = "gap inside control frame";
		    goto bad;
		}
		my $eom = 0; # end of message on end-of-frame + FIN frame
		while ($gap>0) {
		    if ($clen == 0) {
			if (!$clenhi) {
			    $err = "gap larger than frame size";
			    goto bad;
			}
			$clenhi--;
			$clen = 0xffffffff;
			$gap--;
			$current_frame->{mask_offset}
			    = (($current_frame->{mask_offset}||0) + 1) % 4;

		    } elsif ($gap > $clen) {
			$gap -= $clen;
			$current_frame->{mask_offset}
			    = (($current_frame->{mask_offset}||0) + $clen) % 4;
			$clen = 0;
		    } else { # $gap <= $clen
			$clen -= $gap;
			$current_frame->{mask_offset}
			    = (($current_frame->{mask_offset}||0) + $gap) % 4;
			$gap = 0;
		    }
		}
		if (!$clen && !$clenhi) {
		    # frame done
		    $eom = $data_frame->{fin} ? 1:0;
		    $clen = undef;
		}

		if (defined $clen) {
		    $data_frame->{bytes_left} = [$clenhi,$clen];
		} else {
		    delete $data_frame->{bytes_left};
		}
		$self->in_wsdata($dir,$data,$eom,$time,$data_frame);
		if ($eom) {
		    $data_frame = $current_frame = undef;
		    $conn->set_gap_diff($dir,undef);
		} else {
		    delete $data_frame->{init};
		    delete $data_frame->{header};
		}
		return;
	    }

	    $rbuf .= $data;

	    PARSE_DATA:

	    # data for existing frame
	    ############################################################
	    if (defined $clen) {
		my $size = length($rbuf);
		if (!$size and $clen || $clenhi and $eof) {
		    $err = "eof inside websocket frame";
		    goto bad;
		}
		my $fwd = '';
		my $eom = 0;
		while ($size>0) {
		    if ($clen == 0) {
			last if !$clenhi;
			$clenhi--;
			$clen = 0xffffffff;
			$size--;
			$fwd .= substr($rbuf,0,1,'');
		    } elsif ($size > $clen) {
			$size -= $clen;
			$fwd .= substr($rbuf,0,$clen,'');
			$clen = 0;
		    } else {  # $size < $clen
			$clen -= $size;
			$size = 0;
			$fwd .= $rbuf;
			$rbuf = '';
		    }
		}
		if (!$clen && !$clenhi) {
		    # frame done
		    $eom = $current_frame->{fin} ? 1:0;
		    $clen = undef;
		}
		if ($data_frame && $current_frame == $data_frame) {
		    if (defined $clen) {
			$data_frame->{bytes_left} = [$clenhi,$clen];
		    } else {
			delete $data_frame->{bytes_left};
		    }
		    $self->in_wsdata($dir,$fwd,$eom,$time,$data_frame);
		    if ($eom) {
			$data_frame = undef;
		    } else {
			delete $data_frame->{init};
			delete $data_frame->{header};
			$current_frame->{mask_offset}
			    = (($current_frame->{mask_offset}||0) + length($fwd)) % 4
			    if defined $clen;
		    }
		} else {
		    # Control frames are read in full and we make sure about
		    # this when reading the header already.
		    die "expected to read full control frame" if defined $clen;

		    if ($current_frame->{opcode} == 0x8) {
			# extract status + reason for close
			if ($fwd eq '') {
			    $current_frame->{status} = 1005; # RFC6455, 7.1.5
			} elsif (length($fwd) < 2) {
			    # if payload it must be at least 2 byte for status
			    $err = "invalid length for close control frame";
			    goto bad;
			} else {
			    ($current_frame->{status},$current_frame->{reason})
				= unpack("na*",$current_frame->unmask($fwd));
			}
		    }
		    $self->in_wsctl($dir,$fwd,$time,$current_frame);
		}
		goto done if !$size;
		goto PARSE_DATA;
	    }

	    # start of new frame: read frame header
	    ############################################################
	    goto done if $eof;
	    goto hdr_need_more if length($rbuf)<2;

	    (my $flags,$clen) = unpack("CC",$rbuf);
	    my $mask = $clen & 0x80;
	    $clen &= 0x7f;
	    $clenhi = 0;
	    my $off = 2;

	    if ($clen == 126) {
		goto hdr_need_more if length($rbuf)<4;
		($clen) = unpack("xxn",$rbuf);
		goto bad_length if $clen<126;
		$off = 4;
	    } elsif ($clen == 127) {
		goto hdr_need_more if length($rbuf)<10;
		($clenhi,$clen) = unpack("xxNN",$rbuf);
		goto bad_length if !$clenhi && $clen<2**16;
		$off = 10;
	    }
	    if ($mask) {
		goto hdr_need_more if length($rbuf)<$off+4;
		($mask) = unpack("x${off}a4",$rbuf);
		$off+=4;
	    } else {
		$mask = undef;
	    }

	    my $opcode = $flags & 0b00001111;
	    my $fin    = $flags & 0b10000000;
	    goto reserved_flag if $flags & 0b01110000;

	    if ($opcode >= 0x8) {
		# control frame
		goto reserved_opcode if $opcode >= 0xb;
		if (!$fin) {
		    $err = "fragmented control frames are forbidden";
		    goto bad;
		}
		if ($clenhi || $clen>125) {
		    $err = "control frames should be <= 125 bytes";
		    goto bad;
		}
		# We like to forward control frames as a single entity, so make
		# sure we get the whole (small) frame at once.
		goto hdr_need_more if $off+$clen > length($rbuf);

		$current_frame = $ctl_frame
		    ||= Net::Inspect::L7::HTTP::WebSocket::_WSFrame->new;
		%$current_frame = (
		    opcode => $opcode,
		    defined($mask) ? ( mask => $mask ):()
		);
		$got_close = 1 if $opcode == 0x8;

	    } elsif ($opcode>0) {
		# data frame, but no continuation
		goto reserved_opcode if $opcode >= 0x3;
		if ($got_close) {
		    $err = "data frame after close";
		    goto bad;
		}
		if ($data_frame) {
		    $err = "new data message before end of previous message";
		    goto bad;
		}
		$current_frame = $data_frame
		    = Net::Inspect::L7::HTTP::WebSocket::_WSFrame->new;
		%$current_frame = (
		    opcode => $opcode,
		    $fin ? ( fin => 1 ):(),
		    init => 1,  # initial data
		    defined($mask) ? ( mask => $mask ):()
		);

	    } else {
		# continuation frame
		if (!$data_frame) {
		    $err = "continuation frame without previous data frame";
		    goto bad;
		}
		$current_frame = $data_frame;
		%$current_frame = (
		    opcode => $data_frame->{opcode},
		    $fin ? ( fin => 1 ):(),
		    defined($mask) ? ( mask => $mask ):()
		);
	    }

	    # done with frame header
	    $current_frame->{header} = substr($rbuf,0,$off,'');
	    goto PARSE_DATA;

	    # Done
	    ############################################################

	    hdr_need_more:
	    $clen = undef; # re-read from start if frame next time
	    return;

	    done:
	    if ($eof) {
		# forward eof as special wsctl with no frame
		# FIXME: complain if we have eof but the current frame is not
		# done yet.
		$self->in_wsctl($dir,'',$time);
	    } elsif (defined $clen) {
		# We have at least the header of a data frame (control frames
		# are read as a single entity) and might need more data
		# (clen>0). Set gap_diff.
		$clen>0 and $conn->set_gap_diff($dir,
		    ! $clenhi ? $clen :           # len <=32 bit
		    1 << 32 == 1 ? 0xffffffff :   # maxint on 32-bit platform
		    ($clenhi << 32) + $clen       # full 64 bit
		);
	    }
	    return;

	    bad_length:
	    $err ||= "non-minimal length representation in websocket frame";
	    reserved_flag:
	    $err ||= "extensions using reserved flags are not supported";
	    reserved_opcode:
	    $err ||= "no support for opcode $opcode";

	    bad:
	    $conn->{error} = 1;
	    $self->fatal($err,$dir,$time);
	    return;
	};
    }

    return sub {
	my $dir = shift;
	goto &{$sub[$dir]};
    }
}

{
    package Net::Inspect::L7::HTTP::WebSocket::_WSFrame;
    sub new { bless {}, shift };
    sub unmask {
	my ($self,$data) = @_;
	return $data if $data eq '' or ! $self->{mask};
	my $l = length($data);
	$data ^= substr($self->{mask} x int($l/4+2),$self->{mask_offset}||0,$l);
	return $data;
    };
}

1;

__END__
=head1 NAME

Net::Inspect::L7::HTTP::WebSocket - implements WebSocket-upgrade

=head1 SYNOPSIS

 package myRequest;
 use base 'Net::Inspect::Flow';

 # define methods needed by Net::Inspect::L7::HTTP
 sub in_request_header { ... }
 ...

 use base 'Net::Inspect::L7::HTTP::WebSocket';
 # define the methods needed for WebSockets
 sub in_wsctl  { ... }
 sub in_wsdata { ... }

=head1 DESCRIPTION

This module implements the C<upgrade_websocket> method which gets called by
L<Net::Inspect::L7::HTTP> if an upgrade to websockets is encountered:

=over 4

=item $request->update_websocket($conn,$request,$response) -> $sub

If this function is implemented in the request object by deriving from this
class it will check if the current upgrade is a valid websocket upgrade by
inspecting C<$request> and <$response>. These hashes are a the result of
C<parse_reqhdr> and C<parse_rsphdr> in L<Net::Inspect::L7::HTTP>.

The L<Net::Inspect::L7::HTTP> object is also given, because it will be used (as
a weak reference) in the callback C<$sub> which gets returned if the connection
upgrade was considered is valid.

This callback C<$sub> will then be called as
C<< $sub->($dir,$data,$eof,$time) >> similar to C<in_data> as documented in
L<Net:Inspect::L7::HTTP>. Based on the input C<$sub> will then forward to
C<in_wsctl> or C<in_wsdata> which need to be defined by the request object.

If the upgrade fails because the information sent in the headers are not
correct the function will throw an error (i.e. die()) which will be catched by
the caller C<$conn> and will cause the connection to be declared bad.

=back

The following functions will be called on new data and will need to be defined
by the request object:

=over 4

=item $request->in_wsctl($dir,$data,$time,$frameinfo)

This will be called after a Websocket upgrade when receiving a control frame.
C<$dir> is 0 for data from client, 1 for data from server.
C<$data> is the unmasked payload of the frame.
C<$frameinfo> is a blessed hash reference which contains the C<opcode> of the
frame, the C<mask> (binary) and C<header> for the frame header.
For a close frame it will also contain the extracted C<status> code and the
C<reason>.

To get the unmasked payload call C<< $frameinfo->unmask($masked_data) >>.

C<in_wsctl> will be called on connection close with C<$data> of C<''> and no
C<\%frameinfo> (i.e. no hash reference).

=item $request->in_wsdata($dir,$data,$eom,$time,$frameinfo)

This will be called after a Websocket upgrade when receiving data inside a data
frame. Contrary to (the short) control frames the data frame must not be read
fully before calling C<in_wsdata>.

C<$dir> is 0 for data from client, 1 for data from server.
C<$data> is the unmasked payload of the frame.
C<$eom> is true if the message is done with this call, that is if the data frame
is done and the FIN bit was set on the frame.
C<$frameinfo> is a blessed hash reference which contains the data type as
C<opcode>. This will be the original opcode of the starting frame in case of
fragmented transfer. It will also contain the C<mask> (binary) of the current
frame.

If this is the initial part of the data (i.e. initial frame in possibly
fragmented data and initial data inside this frame) it will also have C<init>
set to true inside C<$frameinfo>.

If there are still unread data within the frame C<$frameinfo> will contain
C<bytes_left> as C<<[hi,low]>> where C<hi> and C<low> are the upper and lower
32 bit parts of the number of outstanding bytes.

If this call to C<in_wsdata> was caused by the start of a new frame and not
further data in the same frame C<header> will be set to the header of this new
frame. In all other cases C<header> is not set.

To get the unmasked payload call C<< $frameinfo->unmask($masked_data) >>.

=back
