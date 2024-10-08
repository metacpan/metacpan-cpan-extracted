use strict;
use warnings;

package Net::IMP::Filter;
use Net::IMP;
use Net::IMP::Debug;
use Hash::Util 'lock_ref_keys';
use Scalar::Util 'weaken';


############################################################################
#  these need to be redefined in subclass
############################################################################
# analyzed data output
sub out {
    my ($self,$dir,$data) = @_;
    return;
}

sub deny {
    my ($self,$msg,$dir,@extmsg) = @_;
    while (@extmsg) {
	my ($k,$v) = splice(@extmsg,0,2);
	$msg .= " $k:$v";
    }
    $DEBUG && debug("deny $msg");
    return;
}

sub fatal {
    my ($self,$msg) = @_;
    $DEBUG && debug("fatal $msg");
    return;
}

sub log {
    my ($self,$level,$msg,$dir,$offset,$len,@extmsg) = @_;
    while (@extmsg) {
	my ($k,$v) = splice(@extmsg,0,2);
	$msg .= " $k:$v";
    }
    $DEBUG && debug("log [$level] $msg");
    return;
}

sub acctfld {
    my ($self,$key,$value) = @_;
    $DEBUG && debug("acctfld $key=$value");
    return;
}

############################################################################
#  Implementation
############################################################################
sub new {
    my ($class,$imp,%args) = @_;
    if (ref($class)) {
	%args = (%$class, %args);
	$imp ||= $class->{imp};
    }
    my $self = lock_ref_keys( bless {
	%args,
	imp   => $imp,    # analyzer object
	buf   => [
	    # list of buffered data [ offset,buf,type ] per dir
	    # buffers for same streaming type will be concatenated
	    [ [0,'',0] ],
	    [ [0,'',0] ],
	],
	pass    => [0,0], # may pass up to this offset
	prepass => [0,0], # may prepass up to this offset
	skipped => [0,0], # flag if last data got not send to analyzer
			  # because of pass into future
	eof     => [0,0], # flag if eof received
	dead    => 0,     # set if deny|fatal received
    },(ref $class || $class) );

    if ($imp) {
	weaken( my $weak = $self );
	$imp->set_callback(\&_imp_cb,$weak);
    }
    return $self;
}

# data into analyzer
sub in {
    my ($self,$dir,$data,$type) = @_;
    $self->{dead} and return;

    $type ||= IMP_DATA_STREAM;
    $DEBUG && debug("in($dir,$type) %d bytes",length($data));

    $self->{eof}[$dir] = 1 if $data eq '';
    return $self->out($dir,$data,$type) if ! $self->{imp};

    my $buf = $self->{buf}[$dir];

    # (pre)pass as much as possible
    for my $w (qw(pass prepass)) {
	my $maxoff = $self->{$w}[$dir] or next;
	@$buf == 1 and ! $buf->[0][2] or die "buf should be empty";
	if ( $maxoff == IMP_MAXOFFSET
	    or $maxoff > $buf->[-1][0] + length($data) ) {
	    $DEBUG && debug("can $w everything");
	    my $lastoff = $self->{skipped}[$dir] && $buf->[0][0];
	    $buf->[0][0] += length($data);
	    $self->out($dir,$data,$type);
	    if ($w eq 'prepass') {
		$self->{imp}->data($dir,$data,$lastoff,$type);
		$self->{skipped}[$dir] = 0;
	    } elsif ( $data eq '' and $maxoff != IMP_MAXOFFSET ) {
		$self->{imp}->data($dir,$data,$lastoff,$type);
		$self->{skipped}[$dir] = 0;
	    } else {
		$self->{skipped}[$dir] = 1;
	    }
	    return;
	}

	my $canfw = $maxoff - $buf->[-1][0];
	if ( $type > 0 and $canfw != length($data)) {
	    # packet types need to be handled as a single piece
	    debug("partial $w for $type ignored");
	    next;
	}

	$DEBUG && debug("can $w %d bytes of %d", $canfw, length($data));
	my $fwd = substr($data,0,$canfw,'');
	my $lastoff = $self->{skipped}[$dir] && $buf->[0][0];
	$buf->[0][0] += length($fwd);
	$self->{$w}[$dir] = 0; # no more (pre)pass
	$self->out($dir,$fwd,$type);
	if ($w eq 'prepass') {
	    $self->{imp}->data($dir,$fwd,$lastoff,$type);
	    $self->{skipped}[$dir] = 0;
	} else {
	    $self->{skipped}[$dir] = 1;
	}
    }

    # data left which need to be forwarded to analyzer
    if ( ! $buf->[-1][2] ) {
	# replace empty (untyped) buffer with new data
	$buf->[-1][1] = $data;
	$buf->[-1][2] = $type;
    } elsif ( $type < 0 and $buf->[-1][2] == $type ) {
	# streaming data of same type can be added to current buffer
	$buf->[-1][1] .= $data;
    } else {
	# need new buffer
	push @$buf,[
	    $buf->[-1][0] + length($buf->[-1][1]),  # base = end of last
	    $data,
	    $type
	];
    }

    $DEBUG && debug("buffer and analyze %d bytes of data", length($data));
    my $lastoff = $self->{skipped}[$dir] && $buf->[0][0];
    $self->{imp}->data($dir,$data,$lastoff,$type);
    $self->{skipped}[$dir] = 0;
}

# callback from analyzer
sub _imp_cb {
    my $self = shift;
    $self->{dead} and return;

    my @fwd;
    for my $rv (@_) {
	my $rtype = shift(@$rv);
	$DEBUG && debug("$rtype ".join(" ",map { "'$_'" } @$rv));

	if ( $rtype == IMP_DENY ) {
	    my ($dir,$msg,@extmsg) = @$rv;
	    $self->deny($msg,$dir,@extmsg);
	    $self->{dead} = 1;
	    return;
	} elsif ( $rtype == IMP_FATAL ) {
	    my $reason = shift;
	    $self->fatal($reason);
	    $self->{dead} = 1;
	    return;

	} elsif ( $rtype == IMP_LOG ) {
	    my ($dir,$offset,$len,$level,$msg,@extmsg) = @$rv;
	    $self->log($level,$msg,$dir,$offset,$len,@extmsg);

	} elsif ( $rtype == IMP_ACCTFIELD ) {
	    my ($key,$value) = @$rv;
	    $self->acctfld($key,$value);

	} elsif ( $rtype == IMP_PASS or $rtype == IMP_PREPASS ) {
	    my ($dir,$offset) = @$rv;
	    $DEBUG && debug("got %s %d|%d", $rtype,$dir,$offset);

	    if ( $self->{pass}[$dir] == IMP_MAXOFFSET ) {
		next; # cannot get better than previous pass
	    } elsif ( $rtype == IMP_PASS ) {
		if ( $offset == IMP_MAXOFFSET ) {
		    $self->{pass}[$dir] = $offset;
		    $self->{prepass}[$dir] = 0;
		} elsif ( $offset > $self->{pass}[$dir] ) {
		    $self->{pass}[$dir] = $offset;
		    $self->{prepass}[$dir] = 0
			if $offset >= $self->{prepass}[$dir];
		} else {
		    next; # not better than previous pass
		}

	    # IMP_PREPASS
	    } elsif ( $offset == IMP_MAXOFFSET or (
		$offset > $self->{pass}[$dir] and
		$offset > $self->{prepass}[$dir] )) {
		# update for prepass
		$self->{prepass}[$dir] = $offset
	    } else {
		# next; # no better than previous prepass
	    }

	    my $buf = $self->{buf}[$dir];
	    my $end;

	    while ($buf->[0][2]) {
		my $buf0 = shift(@$buf);
		$end = $buf0->[0] + length($buf0->[1]);
		if ( $offset == IMP_MAXOFFSET
		    or $offset >= $end ) {
		    $DEBUG && debug("pass complete buf");
		    push @fwd, [ $dir, $buf0->[1], $buf0->[2] ];
		    # keep dummy in buf
		    if ( ! @$buf ) {
			unshift @$buf,[ $buf0->[0] + length($buf0->[1]),'',0 ];
			push @fwd,[$dir,'',$buf0->[2]]
			    if $self->{eof}[$dir]; # fwd eof
			last;
		    }
		} elsif ( $offset <  $buf0->[0] ) {
		    $DEBUG && debug("duplicate $rtype $offset ($buf0->[0])");
		    unshift @$buf,$buf0;
		    last;
		} elsif ( $offset ==  $buf0->[0] ) {
		    # at border, e.g. forward 0 bytes
		    unshift @$buf,$buf0;
		    last;
		} elsif ( $buf0->[2] < 0 ) {
		    # streaming type, can pass part of buf
		    $DEBUG && debug("pass part of buf");
		    push @fwd, [
			$dir,
			substr($buf0->[1],0,$offset - $end,''),
			$buf0->[2],
		    ];
		    # put back with adjusted offset
		    $buf0->[0] = $offset;
		    unshift @$buf, $buf0;
		    last;
		} else {
		    $DEBUG && debug(
			"ignore partial $rtype for $buf0->[2] (offset=$offset,pos=$buf0->[0])");
		    unshift @$buf, $buf0; # put back
		    last;
		}
	    }

	    if ( $offset != IMP_MAXOFFSET and $offset <= $end ) {
		# limit reached, reset (pre)pass
		$self->{ $rtype == IMP_PASS ? 'pass':'prepass' }[$dir] = 0;
	    }

	} elsif ( $rtype == IMP_REPLACE ) {
	    my ($dir,$offset,$newdata) = @$rv;
	    $DEBUG && debug("got %s %d|%d", $rtype,$dir,$offset);

	    if ( $self->{pass}[$dir] or $self->{prepass}[$dir] ) {
		# we are allowed to (pre)pass in future, so we cannot replace
		die "cannot replace already passed data";
	    }

	    my $buf = $self->{buf}[$dir];
	    my $buf0 = $buf->[0];
	    my $eob = $buf0->[0] + length($buf0->[1]);
	    if ( $eob < $offset ) {
		die "replacement cannot span different types or packets";
	    } elsif ( $eob == $offset ) {
		# full replace
		$DEBUG && debug("full replace");
		push @fwd,[ $dir,$newdata,$buf0->[2] ];
		shift(@$buf);
		push @$buf, [ $eob,'',0 ] if ! @$buf;
	    } else {
		die "no partial replacement for packet types allowed"
		    if $buf0->[2]>0;
		$DEBUG && debug("partial replace");
		push @fwd,[ $dir,$newdata,$buf0->[2] ];
		substr( $buf0->[1],0,$offset - $buf0->[0],'');
		$buf0->[0] = $offset;
	    }

	} elsif ( $rtype == IMP_PAUSE or $rtype == IMP_CONTINUE ) {
	    # ignore
	} else {
	    die "cannot handle Net::IMP rtype $rtype";
	}
    }
    $self->out(@$_) for (@fwd);
}


1;
__END__

=head1 NAME

Net::IMP::Filter - simple data filter using Net::IMP analyzers

=head1 SYNOPSIS

    package myFilter;
    use base 'Net::IMP::Filter';
    sub out {
	my ($self,$dir,$data) = @_;
	print "[$dir] $data\n";
    }

    package main;
    use Net::IMP::Pattern;
    my $factory = Net::IMP::Pattern->new_factory...;
    my $f = myFilter->new( $factory->new_analyzer );
    ..
    $f->in(0,$data0);
    $f->in(1,$data1);
    ..

=head1 DESCRIPTION

C<Net::IMP::Filter> is a class which can be used for simple filters (e.g. data
in, data out) using Net::IMP analyzers, thus hiding the complexity but also
useful features of the Net::IMP interface for simple use cases.
To create such a filter subclass from C<Net::IMP::Filter> and implement any of
the following methods (which by default do nothing):

=over 4

=item out($self,$dir,$data)

this gets called for output of data

=item deny($self,$msg,$dir)

this gets called on IMP_DENY

=item fatal($self,$msg)

this gets called on IMP_FATAL

=item log($self,$level,$msg,$dir,$offset,$len)

this gets called on IMP_LOG

=item acctfld($self,$key,$value)

this gets called on IMP_ACCTFIELD

=back

To use the module the following subroutines are defined

=over 4

=item new($class,$factory,%args) 

This function creates a new filter object. 
C<%args> will be put as keys into the objects hash and thus be available to the
methods described above.

=item in($self,$dir,$data,$type)

This method puts new data C<$data> for direction C<$dir> with type C<$type> into
the filter object, which will then send it to the analyzer and finally result in
calls to C<out>, C<deny>, C<log> etc.

=back

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
