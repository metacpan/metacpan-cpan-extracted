############################################################################
# TCP
# opens und closes connections and feeds data into them
# reorders packets based on sequence number
############################################################################
use strict;
use warnings;
package Net::Inspect::L4::TCP;
use base 'Net::Inspect::Flow';
use fields qw(conn);
use Net::Inspect::Debug qw( debug trace );

# field conn
# hash indexed by {saddr,sport,daddr,dport} with values
# [ \@d0,\@d1,$conn ]
#   $conn - connection object
#   \@d0,\@d1 - information about data from client(0) or server(1).
#      [$sn,\%pkt,\@buf,$state]
#        $sn - all packets received up to this sequence number
#        \%pkt - packets which are not added to \@buf (out of order, missing
#          packet in between): sn -> [pkt,time]
#        \@buf - ordered data which are not yet forwarded to attached flows [pkt,time]
#        $state - bitmask ( 0b0000FfSs : Fin+ack|Fin|Syn+ack|Syn)

use constant {
    D_SN    => 0,
    D_OPKT  => 1,
    D_BUF   => 2,
    D_STATE => 3,
    D_TTL   => 4,

    C_DIR0  => 0,
    C_DIR1  => 1,
    C_OBJ   => 2,

    P_DATA  => 0,
    P_TIME  => 1,
};

sub new {
    my ($class,$flow) = @_;
    my $self = $class->SUPER::new($flow);
    $self->{conn} = {};
    return $self;
}

sub pktin {
    my Net::Inspect::L4::TCP $self = shift;
    my ($pkt,$meta) = @_;
    return if $meta->{proto} != 6; # does only handle tcp

    # extract TCP header
    my ($sport,$dport,$sn,$asn,$doc,$window,$cksum,$up)
	= unpack('nnNNnnnn',$pkt);

    # payload
    my $do = ( $doc >> 12 )*4;
    my $buf = substr($pkt,$do);

    # flags
    my $urg = $doc & 0b100000 && 1;
    my $ack = $doc & 0b010000 && 1;
    my $psh = $doc & 0b001000 && 1;
    my $rst = $doc & 0b000100 && 1;
    my $syn = $doc & 0b000010 && 1;
    my $fin = $doc & 0b000001 && 1;

    debug("%s%s%ssn=%u len=%d",
	$syn ? 'SYN ':'',
	$fin ? "FIN ":'',
	$ack ? "ACK=$asn ":'',
	$sn,
	length($buf));

    my $saddr = $meta->{saddr};
    my $daddr = $meta->{daddr};

    # find or create connection
    my ($conn,$dir);
    if ( $conn = $self->{conn}{$saddr,$sport,$daddr,$dport} ) {
	$dir = 0;
	debug("found conn $conn $saddr.$sport(%04b) -> $daddr.$dport(%04b)",
	    $conn->[C_DIR0][D_STATE],$conn->[C_DIR1][D_STATE] );
    } elsif ( $conn = $self->{conn}{$daddr,$dport,$saddr,$sport} ) {
	$dir = 1;
	# saddr should point to client all time..
	($saddr,$sport,$daddr,$dport) = ($daddr,$dport,$saddr,$sport);
	debug("found conn $conn $saddr.$sport(%04b) <- $daddr.$dport(%04b)",
	    $conn->[C_DIR0][D_STATE],$conn->[C_DIR1][D_STATE] );
    } else {
	$dir = 0
    }

    # new connection, ISN = $sn
    if ( $syn ) {
	if ( $fin ) {
	    # invalid combination
	    trace("FIN+SYN($dir) for connection $saddr.$sport -> $daddr.$dport - ignoring");
	    return 1;
	}

	debug("SYN($dir) for new flow $saddr.$sport -> $daddr.$dport");
	if ( $conn and $conn->[$dir][D_STATE] & 0b0001 ) {
	    # SYN already received, duplicate?
	    trace("duplicate SYN($dir) for connection $saddr.$sport -> $daddr.$dport - ignoring");
	    return 1;
	}
	if ( ! $conn ) {
	    my $rv = $self->syn({
		time  => $meta->{time},
		saddr => $saddr,
		sport => $sport,
		daddr => $daddr,
		dport => $dport,
		dir   => $dir,
		proto => 6,
	    });
	    if ( defined $rv && ! $rv ) {
		# we don't want a connection for this
		debug("ignored syn $saddr.$sport -> $daddr.$dport because of syn-hook");
		return 1;
	    }
	}

	# dok for structure see top of file
	if ( ! $conn ) {
	    $conn = [ 
		[ undef,{},[],0],  # C_DIR0: D_SN, D_OPKT, D_BUF, D_STATE
		[ undef,{},[],0],  # C_DIR1: D_SN, D_OPKT, D_BUF, D_STATE
		undef              # C_OBJ
	    ];
	    # register new connection
	    debug("register conn $saddr.$sport -> $daddr.$dport $conn");
	    $self->{conn}{$saddr,$sport,$daddr,$dport} = $conn;
	}

	# set ISN and state for direction
	$conn->[$dir][D_SN] = $sn+1;
	$conn->[$dir][D_STATE] = 0b0001;
    }

    # must have $conn here or ignore packet
    if ( ! $conn ) {
	debug("no established connection $saddr.$sport <-> $daddr.$dport");
	return 1;
    }

    if ( $buf ne '' or $fin ) {

	# add buf to packets         P_DATA,P_TIME
	$conn->[$dir][D_OPKT]{$sn} = [$buf,$meta->{time}] if $buf ne '';

	# set FIN flag - no more data expected from peer after this point
	# but outstanding packets might still come in
	if ( $fin ) {
	    if ( not $conn->[$dir][D_STATE] & 0b0100 ) {
		debug("shutdown dir $dir $saddr.$sport -> $daddr.$dport");
		$conn->[$dir][D_STATE] |= 0b0100; # fin received
		# must increase sn for ACK
		$conn->[$dir][D_OPKT]{ ( $sn+length($buf) ) % 2**32  } 
		    = [ '',$meta->{time} ];
	    } else {
		# probably duplicate
		debug("ignore duplicate FIN($dir) $saddr.$sport -> $daddr.$dport");
		return 1;
	    }
	}
    }

    if ( $ack ) {
	my $odir = $dir?0:1;

	# reorder and concat packets up to acknowledged value and forward
	# to attached flows
	my $pkts = $conn->[$odir][D_OPKT];
	my $eof = 0;
	if ( %$pkts ) {
	    my $xsn  = $conn->[$odir][D_SN];
	    my $obuf = $conn->[$odir][D_BUF];
	    while ( $xsn != $asn and $pkts->{$xsn} ) {
		my $pkt = delete $pkts->{$xsn};

		# apply ACK to $pkt
		if ( $pkt->[P_DATA] ne '' ) {
		    my $acklen = ($xsn <= $asn) ? $asn - $xsn : 2**32 - $xsn + $asn;
		    if ($acklen >= length($pkt->[P_DATA])) {
			# ACK for full length
			$xsn = ( $xsn + length($pkt->[P_DATA]) ) % 2**32;
			# ACK to FIN might ack previous packets too, so insert
			# empty dummy packet for FIN if necessary
			$pkts->{$xsn} ||= [ '',$pkt->[P_TIME] ];
		    } else {
			# Only part of $pkt got acked. Put rest back with new xsn.
			$xsn = ( $xsn + $acklen ) % 2**32;
			$pkts->{$xsn} and die "have already D_OPKT entry for $xsn";
			$pkts->{$xsn} = $pkt;
			$pkt = [ substr($pkt->[P_DATA],0,$acklen,''), $pkt->[P_TIME] ];
		    }

		} else {
		    debug("got ACK for FIN($odir)");
		    $xsn = ( $xsn + 1 ) % 2**32;

		    # eof - set to 2 if both sides closed
		    $eof = $conn->[$dir][D_STATE] & 0b1000 ? 2:1;
		}

		# Add $pkt to D_BUF
		# merge packets which came later but are earlier in the stream
		# into $pkt
		if ( @$obuf && $obuf->[-1][P_TIME] >= $pkt->[P_TIME] ) {
		    # merge with existing entry
		    $obuf->[-1][P_DATA] .= $pkt->[P_DATA]
		} else {
		    # create new entry in obuf
		    push @$obuf,$pkt
		}

		if ($eof) {
		    # upper flow needs to process all remaining data on eof, so
		    # pack them together
		    if (@$obuf>1) {
			$pkt = shift(@$obuf);
			$pkt->[P_DATA] .= $_->[P_DATA] for(@$obuf);
			@$obuf = $pkt;
		    }

		    # ignore data after fin
		    if ( %$pkts) {
			trace("ignoring packets after FIN($odir) $saddr.$sport -> $daddr.$dport");
			%$pkts = ();
		    }

		    last;
		}
	    }

	    # lost packets or ack points in the middle of packet
	    if ( $xsn != $asn ) {
		trace("lost packets before ACK($odir)=$asn SN($odir)=$xsn $saddr.$sport -> $daddr.$dport");
		delete $self->{conn}{$saddr,$sport,$daddr,$dport};
		if ( my $obj = $conn->[C_OBJ] ) {
		    $obj->fatal( "lost packets before ACK($odir)=$asn, SN($odir)=$xsn",
			$dir,$meta->{time});
		}
		return 1;
	    }

	    # update sn etc
	    $conn->[$odir][D_SN] = $xsn;
	    $conn->[$odir][D_STATE] |= 0b1000 if $eof;

	    # forward data
	    if ( my $obj = $conn->[C_OBJ] ) {
		while ( my $buf = shift(@$obuf) ) {
		    my $n = ($eof || $buf->[P_DATA] ne '')
			? $obj->in($odir,$buf->[P_DATA],$eof,$buf->[P_TIME])
			: 0;

		    if ( ! defined $n ) {
			# error processing -> close
			# don't call fatal, hook probably reported error already
			trace("error processing data in hook in $saddr.$sport -> $daddr.$dport");
			delete $self->{conn}{$saddr,$sport,$daddr,$dport};
			return 1;
		    } elsif ( $n == length($buf->[P_DATA]) ) {
			# everything processed
			next;
		    } elsif ( $eof ) {
			$obj->fatal("handler did not eat all data on eof",$dir,$meta->{time});
			return 1;
		    } elsif (!$n) {
			# Processed nothing, which means we need more data.
			# Try to merge this buffer into next one in the hope
			# that we can process the data together
			if (@$obuf) {
			    $obuf->[-1][P_DATA] =
				$buf->[P_DATA] . $obuf->[-1][P_DATA];
			    debug("merge %d bytes into next buffer for $odir",
				length($buf->[P_DATA]));
			    next;
			}

			# no more data yet:
			# put buffer back and wait for more data
			debug("keep full buffer (%d bytes) for $odir",length($buf->[P_DATA]));
			unshift @$obuf,$buf;
			last;

		    }  else {
			# keep bytes in $buf which were not processed
			substr($buf->[P_DATA],0,$n,'');
			debug("keep %d bytes in buffer for $odir",length($buf->[P_DATA]));
			unshift @$obuf,$buf;
			last;
		    }
		}
	    }

	    # eof: if other side fin+acked too reap connection
	    if ( $eof == 2 ) {
		debug("connection  $saddr.$sport -> $daddr.$dport closed");
		delete $self->{conn}{$saddr,$sport,$daddr,$dport};
		return 1;
	    }
	}

	# check for ACK to SYN
	my $osn = $conn->[$odir][D_SN];
	if ( ! defined $osn ) {
	    # got ack w/o syn?
	    trace("received ACK w/o SYN for dir=$odir $saddr.$sport -> $daddr.$dport");
	    return 1;
	}

	# ACK for SYN?
	if ( not $conn->[$odir][D_STATE] & 0b0010 ) {
	    # check that ACK matches ISN from SYN
	    if ( $osn % 2**32 != $asn ) {
		trace("got ACK($asn) which does not match SYN($osn)");
		return 1;
	    }
	    # ack ok
	    $conn->[$odir][D_STATE] |= 0b0010;
	    $conn->[$dir][D_TTL] = $meta->{ttl};
	    debug("got ACK for SYN($odir)");

	    # got other side syn+ack too? -> new connection
	    if ( $conn->[$dir][D_STATE] & 0b0010 ) {
		# make connection object
		my $obj = $self->new_connection({
		    time  => $meta->{time},
		    saddr => $saddr,
		    sport => $sport,
		    daddr => $daddr,
		    dport => $dport,
		    ttl   => $conn->[1][D_TTL],
		});
		if ( ! $obj ) {
		    # hook says ignore connection
		    debug("ignoring connection $saddr.$sport -> $daddr.$dport because of hook");
		    delete $self->{conn}{$saddr,$sport,$daddr,$dport};
		    return 1;
		}
		debug("created object for $saddr.$sport -> $daddr.$dport $obj");
		$conn->[C_OBJ] = $obj;
	    }
	}
    }

    return 1;
}

sub syn { shift->{upper_flow}->syn(@_) }
sub new_connection { shift->{upper_flow}->new_connection(@_) }

sub expire {
    my ($self,$time) = @_;
    while (my ($k,$c) = each %{$self->{conn}} ) {
	$c->[C_OBJ] or next;
	$c->[C_OBJ]->expire($time) or next;
	delete $self->{conn}{$k}
    }
}


1;

__END__

=head1 NAME

Net::Inspect::L4::TCP - get IP data, extracts TCP connections

=head1 SYNOPSIS

 my $tcp = Net::Inspect::L4::TCP->new;
 my $raw = Net::Inspect::L3::IP->new($tcp);
 $tcp->pktin($data,\%meta);

=head1 DESCRIPTION

Gets IP packets via C<pktin> method and handles connections.

Provides the hooks required by C<Net::Inspect::L3::IP>.

Hooks provided:

=over 4

=item pktin($pkt,$meta)

=back

Hooks called on the attached flow object:

=over 4

=item syn(\%meta)

called when the first SYN is received.
Meta data are saddr, sport, daddr, dport and time.
If returns false the connection will not be setup, but in this case it will be
called on the seconds SYN too (because it does not keep track of ignored
connections).

=item new_connection(\%meta)

will be called if the final ACK for the 3-way handshake is received.
Must return a connection object or the connection will be ignored.
Same meta data as in C<syn>.

The connection object will be stored in the flow as long as the connection
is open. The next hooks will be called on the connection object instead of
the object attached to the flow.

=back

Methods called on the connection object:

=over 4

=item in($dir,$data,$eof,$time)

Will be called when new data arrived and got acked.
C<$dir> is the direction of the data (e.g.  0 for data from client, 1 from
server).
If C<$eof> is 1 only this direction got closed, on 2 both sides got closed.
Otherwise C<$eof> is false.

Must return the number of bytes processed from C<$data>. The rest of the data
will be kept inside the flow object and if new data come in (or FIN gets ACKed)
the hook will be called again with all unprocessed data.

If C<$eof> is true it should better process all data, because the hook will not
be called again for this direction.

C<$time> is the time, when the data arrived. If the data arrived at different
times (like after reordering) the earliest time gets used.

=item fatal($reason,$dir,$time)

Will be called on fatal errors of the connection, e.g. lost packets.

=back

Methods useful for overwriting

=over 4

=item syn(\%meta)

default implementation will just call C<syn> from the attached flow object

=item new_connection(\%meta)

default implementation will just call C<new_connection> from the attached flow
object

=back

=head1 LIMITS

It will not croak on strange flag combinations.

You should regularly call C<expire> otherwise connection missing final
handshake will not be expired.
