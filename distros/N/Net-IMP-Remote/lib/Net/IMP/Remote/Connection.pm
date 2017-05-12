use strict;
use warnings;

package Net::IMP::Remote::Connection;
use fields qw(ev fd rbuf wbuf onwrite onclose need_more_rbuf wire analyzer max_analyzer_id);
use Net::IMP::Remote::Protocol;
use Net::IMP::Debug;
use Scalar::Util 'weaken';
use Errno 'EIO';
use Carp;

sub new {
    my ($class,$fd,$side,%args) = @_;
    my $impl = Net::IMP::Remote::Protocol
	->load_implementation(delete $args{impl});
    my $wire = $impl->new;
    my $self = fields::new($class);
    %$self = (
	ev => delete $args{eventlib},
	fd => $fd,
	rbuf => '',
	need_more_rbuf => 1,
	wbuf => '',
	wire => $wire,
	analyzer => {},
	max_analyzer_id => 1,
    );

    debug("init wire=$self->{wire} self=$self");
    if ( my $buf = $wire->init($side) ) {
	debug("send initial data");
	$self->write($buf) or return;
    }

    return $self;
}

sub onClose {
    my ($self,$cb) = @_;
    $self->{onclose} = $cb
}

sub close:method {
    my ($self,$error) = @_;
    debug("close");
    warn "[$self] error: $error\n" if $error;
    if ( my $ev = $self->{ev} ) {
	$ev->onread($self->{fd},undef);
	$ev->onwrite($self->{fd},undef);
    }
    $self->{onclose}->($error) if $self->{onclose};
    %$self = ();
}

sub add_analyzer {
    my ($self,$obj,$id) = @_;
    if ( ! $id ) {
	while (1) {
	    $id = $self->{max_analyzer_id}++;
	    $id = $self->{max_analyzer_id} = 1 if $id > 0x7fffffff;
	    last if ! $self->{analyzer}{$id};
	}
    } elsif ( $self->{analyzer}{$id} ) {
	return;
    }
    $self->{analyzer}{$id} = $obj;
    return $id;
}

sub weak_add_analyzer {
    my $self = shift;
    my $id = $self->add_analyzer(@_) or return;
    weaken( $self->{analyzer}{$id} );
    return $id;
}

sub get_analyzer {
    my ($self,$id) = @_;
    $self->{analyzer}{$id};
}

sub del_analyzer {
    my ($self,$id) = @_;
    delete $self->{analyzer}{$id};
}

sub rpc {
    my ($self,$call,$actions) = @_;
    my $wire = $self->{wire} or do {
	debug("no more wire there to call @$call");
	return;
    };
    my $buf = $wire->rpc2buf($call);
    if ( defined wantarray ) {
	debug("blocking rpc $call->[0]");
	return $self->write($buf) && 
	    ( $actions ? $self->nextop($actions) : 1 )
    }
    debug("non-blocking rpc $call->[0]");
    $self->write($buf);
    $self->nextop($actions) if $actions;
}

# write data in buffer
# !eventlib || defined wantarray -> blocking write
# otherwise: nonblocking with event handler for writing rest
sub write {
    my $self = shift;
    $self->{wbuf} .= shift if @_;
    if ( $self->{wbuf} eq '' ) {
	debug("nothing to write");
	return 1; # nothing to write
    } elsif ( defined wantarray or ! $self->{ev} ) {
	# blocking write
	while ( $self->{wbuf} ne '' ) {
	    my $n = syswrite($self->{fd},$self->{wbuf});
	    if ( $n ) {
		debug("wrote %d of %d bytes",$n,length($self->{wbuf}));
		substr($self->{wbuf},0,$n,'');
	    } elsif ( ! defined $n and $!{EAGAIN} ) {
		debug("short write - blocking wait for writable socket");
		vec(my $win = '',fileno($self->{fd}),1) = 1;
		select(undef,$win,undef,undef) or do {
		    $self->close("failed to select: $!");
		    return
		}
	    } else {
		$self->close("failed to write: $!");
		return;
	    }
	}
	debug("blocking write completed");
	return 1;
    } else {
	# async write
	my $n = syswrite($self->{fd},$self->{wbuf});
	if ( $n ) {
	    substr($self->{wbuf},0,$n,'');
	    if ( $self->{wbuf} eq '' ) {
		debug("non-blocking write completed");
		return 1;
	    } else {
		debug("non-blocking short write %d of %d",$n,
		    $n+length($self->{wbuf}));
	    }
	} elsif ( $!{EAGAIN} ) {
	    $self->close("failed to write: $!");
	    return;
	}

	debug("async continue write if socket writable");
	$self->{ev}->onwrite( $self->{fd}, $self->{onwrite} ||= do {
	    # callback to write rest of wbuf
	    weaken( my $wself = $self );
	    sub {
		$wself->write() or return while $wself->{wbuf} ne '';
		$wself->{ev}->onwrite($wself->{fd},undef);
	    };
	});
	return 1;
    }
}


# handle single (or up to $max) operation
# !eventlib || defined wantarray -> block until one operation done
# otherwise: setup event handler if no operation fully read yet
sub nextop {
    my ($self,$actions,$max,$incb) = @_;
    my $block = $incb ? 0 : defined wantarray || ! $self->{ev};

    NEXTOP:
    while ( $self->{need_more_rbuf} ) {
	debug("trying to read%s...", $incb ? ' inside read-callback':'' );
	my $n = sysread($self->{fd},$self->{rbuf},8192,length($self->{rbuf}));
	debug("read done -> ".( $n // $! ));
	if ( $n ) {
	    last;
	} elsif ( defined $n ) {
	    # eof
	    if ( $self->{rbuf} eq '' ) {
		$self->close();
		return 0
	    } else {
		# consider eof within data block as error
		$! = EIO;
		$self->close("eof inside operation");
		return;
	    }
	} elsif ( ! $!{EAGAIN} ) {
	    $self->close("failed to read: $!");
	    return;
	} elsif ( $incb ) {
	    # async wait, but we are inside callback already, so just
	    # wait for more data
	    debug("waiting for more inside existing callback");
	    return;
	} elsif ( $block ) {
	    # blocking wait for new data
	    vec(my $rin = '',fileno($self->{fd}),1) = 1;
	    select($rin,undef,undef,undef) or do {
		$self->close("select failed: $!");
		return;
	    };
	    next;
	}

	# async wait for more
	debug("install onread callback for more data");
	weaken(my $wself = $self);
	$self->{ev}->onread($self->{fd}, sub {
	    $wself->nextop($actions,$max,1);
	});
	return;
    }

    my $rpc = $self->{wire}->buf2rpc(\$self->{rbuf});
    if ( ! $rpc ) {
	$self->{need_more_rbuf} = 1;
	goto NEXTOP;
    }

    $self->{need_more_rbuf} = $self->{rbuf} eq '';

    my ($type,@args) = @$rpc;
    #debug(Dumper($rpc)); use Data::Dumper;
    debug("processing $type");
    my $act = $actions->{$type+0} or do {
	$self->close( "no handler for return type $type" );
	return;
    };

    if ( ref($act) eq 'CODE' ) {
	$act->(@args)
    } elsif ( ref($act) eq 'ARRAY' ) {
	if (! @$act) {
	    @$act = @args;
	} else {
	    # assume code+args
	    my ($code,@m) = @$act;
	    $code->(@m,@args);
	}
    } else {
	# assume object
	$act->$type(@args)
    }
    
    --$max if $max && $max>0;
    return 1 if ! $max;        # one-shot or done
    $incb = 0 if $max>0;       # redo onread callback with changed $max
    goto NEXTOP;
}


1;
