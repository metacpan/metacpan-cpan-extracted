#!/usr/bin/perl

use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use Getopt::Long qw(:config posix_default bundling);
use AnyEvent;
use AnyEvent::Socket qw(tcp_server tcp_connect parse_hostport format_address);
use Net::IMP;
use Net::IMP::Cascade;
use Net::IMP::Debug qw(:DEFAULT $DEBUG_RX);
use Carp;

# get a chance to cleanup
$SIG{TERM} = $SIG{INT} = sub { exit(0) };

sub usage {
    print STDERR <<USAGE;

Relay which uses Net::IMP analyzers for inspection and modification of traffic
$0 Options*  --listen ...[ -M|--module ... ]*  --connect...

Options:
  -h|--help               show usage
  -M|--module mod[=arg]   use Net::IMP module for connections
  -L|--listen ip:port     listen on this socket
  -C|--connect target     and forward to this (ip:port,'socks4')
  --http-only             only analyze traffic which looks like http (pass thru https)
  -d|--debug [pkg]        debug mode, if pkg given only packages matching pkg,
			  e.g. 'ContentSecurityPolicy*'

USAGE
    exit(2);
}

my (@listen,@laddr,@module,@debug_pkg,$http_only);
GetOptions(
    'M|module=s'  => \@module,
    'L|listen=s'  => \@laddr,
    'C|connect=s' => sub {
	@laddr or die "specify listener first\n";
	push @listen, [ $_[1], [@module] ,@laddr ];
	@laddr = ();
	@module = ();
    },
    'http-only'   => \$http_only,
    'd|debug:s'   => \@debug_pkg,
    'h|help'      => sub { usage() },

);

if (@debug_pkg) {
    $DEBUG = 1;
    # glob2rx
    s{(\*)|(\?)|([^*?]+)}{ $1 ? '.*': $2 ? '.': "\Q$3" }esg for (@debug_pkg);
    $DEBUG_RX = join('|',@debug_pkg);
}

push @listen, [ undef,@laddr ] if @laddr;
@listen or usage("no listener specified");

# create listeners
my @active_connections;
for my $l (@listen) {
    my ($raddr,$module,@laddr) = @$l;

    my ($shost,$sport);
    ($shost,$sport) = parse_hostport($raddr) or die "invalid raddr $raddr"
	if $raddr and $raddr ne 'socks4';

    my @factory;
    for my $mod (@$module) {
	$mod eq '=' and next;
	my ($class,$args) = $mod =~m{^([a-z][\w:]*)(?:=(.*))?$}i
	    or die "invalid module $mod";
	eval "require $class" or die "cannot load $class args=$args: $@";
	my %args = $class->str2cfg($args//'');
	if ( my @err = $class->validate_cfg(%args)) {
	    die "bad args for $class: @err";
	}
	debug("new factory $class");
	push @factory,$class->new_factory(%args, eventlib => myEvent->new );
    }

    my $imp_factory = 
	! @factory ? undef :
	@factory == 1 ? $factory[0] :
	Net::IMP::Cascade->new_factory( parts => \@factory );

    croak("cannot set interface for IMP factory") if $imp_factory && 
	! $imp_factory->set_interface([
	    IMP_DATA_STREAM,
	    [
		IMP_PASS,
		IMP_PREPASS,
		IMP_DENY,
		IMP_REPLACE,
		IMP_TOSENDER,
		IMP_LOG,
		IMP_ACCTFIELD,
		IMP_PAUSE,
		IMP_CONTINUE,
		IMP_FATAL,
	    ],
	]);

    for my $laddr (@laddr) {
	my ($lhost,$lport) = parse_hostport($laddr) or die "invalid laddr $laddr";
	debug("listen on $lhost,$lport");

	my $fwd = sub {
	    my ($cfh,$chost,$cport,$reply) = @_;
	    #debug("attempting connect to $shost,$sport");
	    tcp_connect($shost,$sport,sub {
		my $sfh = shift;

		#debug("connect to $shost,$sport succeeded");
		if ( $reply ) {
		    if ( syswrite($cfh,$reply) != length($reply)) {
			# should not block on such few bytes, assume error
			debug("syswrite socks reply failed: $!");
			close($cfh);
			return;
		    }
		}

		my $saddr = format_address((AnyEvent::Socket::unpack_sockaddr(getpeername($sfh)))[1]);
		my $laddr = format_address((AnyEvent::Socket::unpack_sockaddr(getsockname($cfh)))[1]);
		my $imp = $imp_factory && $imp_factory->new_analyzer( meta => {
		    app => 'imp_proxy',
		    caddr => $chost, cport => $cport,
		    saddr => $saddr, sport => $sport,
		    laddr => $laddr, lport => $lport,
		});
		push @active_connections, Connection->new($cfh,$sfh,$imp);
	    });
	};

	my $fwd_transp = sub {
	    my ($cfh,$chost,$cport) = @_;
	    # transparent, get target with getsockname
	    ($sport,$shost) = AnyEvent::Socket::unpack_sockaddr(getsockname($cfh));
	    $shost = format_address($shost);
	    if ( $shost eq $lhost and $sport == $lport ) {
		# not transparent
		debug("attempt to connect to transparent socket non-transparently");
		close($cfh);
		return;
	    }
	    $fwd->(@_);
	};

	my $fwd_socks = sub {
	    my ($cfh,$chost,$cport) = @_;
	    my $socks4hdr = '';
	    my $len = 9; # minimal len: 8 byte hdr + 0 byte user + "\0"

	    my $iow;
	    my $iot = AnyEvent->timer( after => 10, cb => sub {
		debug("no socks4 header within 10 seconds");
		$iow = undef;
		close($cfh);
		return;
	    });

	    my $gethdr = sub {
		my $rv = sysread($cfh,$socks4hdr,$len-length($socks4hdr));
		return if ! defined $rv and $!{EAGAIN}; # retry
		if ( ! $rv ) {
		    debug("closed/error before getting socks4 header: $!");
		    $iow = $iot = undef;
		    close($cfh);
		    return;
		}
		return if length($socks4hdr) != $len;

		# found
		$iow = $iot = undef;
		(my $proto, my $typ,$sport,$shost) = unpack('CCna4',$socks4hdr);
		if ( $proto != 4 or $typ != 1 ) {
		    debug("bad sockshdr: proto=$proto, typ=$typ");
		    close($cfh);
		    return;
		}

		if ( substr($socks4hdr,8) !~m{\0} ) {
		    # username given, need more bytes
		    $len++;
		    die "username too long" if $len>512;
		    return;
		}

		my $reply = pack('CCna4',0,90,$sport,$shost);
		$shost = format_address($shost);
		debug("socks4 fwd to $shost,$sport");

		$fwd->($cfh,$chost,$cport,$reply);
	    };

	    $iow = AnyEvent->io(
		fh => $cfh,
		poll => 'r',
		cb => $gethdr,
	    );
	};

	tcp_server($lhost,$lport,
	    ! $raddr ? $fwd_transp :
	    $raddr eq 'socks4' ? $fwd_socks :
	    $fwd
	);
    }
}


# debug info on USR1
my $sw = AnyEvent->signal(
    signal => 'USR1',
    cb => sub {
	debug("-------- active connections -------------");
	$_->dump_state for(@active_connections);
	debug("-----------------------------------------");
    }
);

# timer for expiring connections
my $xpt = AnyEvent->timer(
    after => 5,
    interval => 5,
    cb => sub {
	@active_connections = grep { $_ && $_->{expire} } @active_connections;
	@active_connections or return;
	debug("check timeouts for %d conn",0+@active_connections);
	my $now = AnyEvent->now;
	for (@active_connections) {
	    $_ or next;
	    $_->xdebug("expire=%d now=%d", $_->{expire},$now);
	    $_->{expire} > $now and return;
	    $_->close;
	}
    }
);

# Mainloop
$SIG{PIPE} = 'IGNORE'; # catch EPIPE
my $loopvar = AnyEvent->condvar;
$loopvar->recv;
exit;


############################################################################
# AnyEvent wrapper to privide Net::IMP::Remote etc with acccess to
# IO events
############################################################################
package myEvent;
sub new {  bless {},shift }
{
    my %watchr;
    sub onread {
	my ($self,$fh,$cb) = @_;
	defined( my $fn = fileno($fh)) or die "invalid filehandle";
	if ( $cb ) {
	    $watchr{$fn} = AnyEvent->io( 
		fh => $fh, 
		cb => $cb, 
		poll => 'r' 
	    );
	} else {
	    undef $watchr{$fn};
	}
    }
}

{
    my %watchw;
    sub onwrite {
	my ($self,$fh,$cb) = @_;
	defined( my $fn = fileno($fh)) or die "invalid filehandle";
	if ( $cb ) {
	    $watchw{$fn} = AnyEvent->io( 
		fh => $fh, 
		cb => $cb, 
		poll => 'w' 
	    );
	} else {
	    undef $watchw{$fn};
	}
    }
}

sub now { return AnyEvent->now }
sub timer {
    my ($self,$after,$cb,$interval) = @_;
    return AnyEvent->timer( 
	after => $after, 
	cb => $cb,
	$interval ? ( interval => $interval ):()
    );
}


############################################################################
# Connection object
############################################################################

package Connection;
use Hash::Util 'lock_keys';
use Net::IMP;
use Net::IMP::Debug;
use constant READSZ => 8192;
use Socket 'MSG_PEEK';

my $connid;
BEGIN { $connid = 0 }

sub new {
    my ($class,$cfh,$sfh,$imp) = @_;

    my @fh = ($cfh,$sfh);
    my @eof = (0,0);

    # read and write buffer
    # data are usually read into rbuf, then analyzed and later put into wbuf
    # if no Net::IMP filtering is done we can skip rbuf and write directly
    # to wbuf.
    # If wbuf is not empty the read handler on $from will be disabled
    # and a write handler on $to enabled until all data are written
    my @rbuf = ( '','' );
    my @wbuf = ( '','' );

    # event handlers and watchers
    # AnyEvent disables fd event by deleting the watcher and enables by
    # adding a io-callback. Because regenerating callback all the time
    # is costly we store it here
    my (@rcb,@rwatch);
    my (@wcb,@wwatch);

    my $self = bless {
	expire => AnyEvent->now + 30, # last activity for connection expire
	connid => ++$connid,
    }, $class;

    $self->{closef} = my $close = sub {
	# undef everything which is somehow connected to $self and might
	# hinder destruction by crossreferencing
	$imp && $imp->set_callback(undef);
	@fh = @rcb = @wcb = @rwatch = @wwatch = ();
	$self->{expire} = undef;
    };
    lock_keys(%$self);

    # Net::IMP specific
    my @imp_passed    = (0,0);  # offset of rbuf[0] in stream
    my @imp_topass    = (0,0);  # can pass up to this offset
    my @imp_toprepass = (0,0);  # can prepass up to this offset
    my @imp_skipped   = (0,0);  # flag if data got not send to imp because of pass into future

    # bytes from initial read, used for http_only feature
    my $initial_read = '';

    # defined read handler:
    # read data into rbuf (or wbuf on some optimizations)
    # ---------------------------------------------------------------------
    for my $ft ([0,1],[1,0]) {
	my ($from,$to) = @$ft;
	$rcb[$from] = sub {
	    my $woff = length($wbuf[$to]); # >0 == was stalled
	    #$self->xdebug("read from $from");

	    my ($n,$need_imp);
	    if ( $imp and $http_only and length($initial_read)<10 ) {
		if ( $from == 1 ) {
		    # server sends data before client sends request,
		    # this cannot be http
		    debug("no http because server send first");
		    $imp = undef;
		    $wbuf[$from] = $initial_read;
		    $initial_read = undef;
		} else {
		    my $rv = sysread($fh[$from],$initial_read,10-length($initial_read),length($initial_read));
		    if ( ! defined $rv ) {
			&$close if ! $!{EAGAIN};
			return;
		    } elsif ( $rv == 0 ) { # eof
			# cannot be http
		    } elsif ( length($initial_read)<10 ) {
			# try later
			return;
		    } else {
			debug("got '$initial_read'");
			if ( $initial_read =~m{^([A-Z]{3,})[ \t]} ) {
			    debug("might be HTTP, not ssl at least");
			    $rbuf[$from] = $initial_read;
			    goto is_http;
			}
		    }

		    # not http
		    debug("definitly not HTTP");
		    $imp = undef;
		    $wbuf[$to] = $initial_read;

		    is_http: ;
		    $n = length($initial_read);
		}
	    }

	    if ( ! $imp ) {
		# no analysis, direct read into wbuf
		$n||= sysread($fh[$from],$wbuf[$to],READSZ,$woff)
	    } elsif ( !$n and ( my $sz = ( $imp_topass[$from] == IMP_MAXOFFSET ) 
		? READSZ 
		: $imp_topass[$from]-$imp_passed[$from] ) > 0 ) {
		$self->xdebug("can pass $sz w/o analyzing");
		# no analysis because of pass in future, read directly into wbuf
		$rbuf[$from] eq '' or die "rbuf[$from] should be empty";
		$sz = READSZ if $sz>READSZ;
		$n = sysread($fh[$from],$wbuf[$to],$sz,$woff);
		if ($n) {
		    $imp_skipped[$from] = 1;
		    $imp_passed[$from] += $n;
		}
	    } else {
		# read into rbuf for analysis
		$need_imp = 1;
		$n ||= sysread($fh[$from],$rbuf[$from],READSZ,
		    length($rbuf[$from]));
	    }

	    # error
	    if ( ! defined $n ) {
		return if $!{EAGAIN};
		$self->xdebug("error reading $from: $!");
		&$close;
		return;

	    # eof
	    } elsif ( $n == 0 ) {
		$self->xdebug("eof on $from");

		$eof[$from] = 1;
		# disable further read events
		$rwatch[$from] = undef;

		# send eof to analyzer if it it interested in the data
		if ( $need_imp and (
		    $imp_topass[$from] != IMP_MAXOFFSET )) {
		    if ( $imp_skipped[$from] ) {
			$imp_skipped[$from] = 0;
			$imp->data($from,'',
			    $imp_passed[$from] + length($rbuf[$from]));
		    } else {
			$imp->data($from,'');
		    }

		    # connection might have been closed by Net::IMP callback
		    @wcb or return;
		}

		if ( $eof[$to] ) {
		    $self->xdebug("end of connection");
		    &$close;
		    return;
		} elsif ( $wbuf[$to] eq ''
		    and $rbuf[$from] eq '' ) {
		    $self->xdebug("shutdown $to,1");
		    # write close $to if everything was written
		    shutdown($fh[$to],1);
		    # short expire
		    $self->{expire} = AnyEvent->now + 5;
		} else {
		    debug("wait until buffers are empty wbuf[$to]='$wbuf[$to]' rbuf[$from]='$rbuf[$from]'");
		}

	    # send new data to analyzer or
	    # try to write new data immediatly if not stalled
	    } else {
		$self->{expire} = AnyEvent->now + 30;

		# feed analyzer with new bytes
		if ( $need_imp ) {
		    if ( $imp_skipped[$from] ) {
			$imp_skipped[$from] = 0;
			$imp->data($from, substr($rbuf[$from],-$n),
			    $imp_passed[$from] + length($rbuf[$from]) -$n );
		    } else {
			$imp->data($from, substr($rbuf[$from],-$n));
		    }

		    # connection might have been closed by Net::IMP callback
		    @wcb or return;
		}

		# prepass data?
		if ( $imp_toprepass[$from] == IMP_MAXOFFSET ) {
		    $imp_passed[$from] += length($rbuf[$from]);
		    $wbuf[$to] .= $rbuf[$from];
		    $rbuf[$from] = '';
		} elsif ( $imp_toprepass[$from] ) {
		    my $diff = $imp_toprepass[$from] - $imp_passed[$from];
		    if ($diff>0) {
			# smthg to prepass
			my $l = length($rbuf[$from]);
			if ( $diff<=$l ) {
			    $l = $diff; # can pass less/eq than I have
			    $imp_toprepass[$from] = 0;
			}
			$imp_passed[$from] += $l;
			$wbuf[$to] .= substr($rbuf[$from],0,$l,'');
		    } else {
			# reset prepass, because it's done
			$imp_toprepass[$from] = 0;
		    }
		}

		# write if new data and was not stalled
		$wcb[$to](1) if ! $woff and $wbuf[$to] ne '';
	    }
	};
    }

    # define write handler: write data from wbuf
    # if after write attempt still data in wbuf it will stall the connection
    # (disable read, setup write handler) and unstall it once wbuf is empty again
    # ---------------------------------------------------------------------
    for my $ft ([0,1],[1,0]) {
	my ($from,$to) = @$ft;
	$wcb[$to] = sub {
	    my $quick = shift;
	    return if $wbuf[$to] eq '';
	    #$self->xdebug("write to $to");
	    my $n = syswrite( $fh[$to], $wbuf[$to] );

	    # error
	    if ( ! $n ) { # XXX $n == 0 should never happen?
		return if $!{EAGAIN};
		$self->fatal("connection($to) broke: $!");

	    # partial write
	    } elsif ( length($wbuf[$to]) < $n ) {
		substr($wbuf[$to],0,$n,'');
		$quick or return; # was already stalled

		# call was from non-stalled connection, make it stalled
		# by disabling read and setting up write handler
		$self->xdebug("connection stalled");
		$rwatch[$from] = undef;
		$wwatch[$to] = AnyEvent->io(
		    fh => $fh[$to],
		    poll => 'w',
		    cb => $wcb[$to]
		);

	    # full write
	    } else {
		$wbuf[$to] = '';

		if ( ! $quick ) {
		    # call was from stalled connection, which is no longer
		    # stalled. Disable write handler and enable read handler
		    $self->xdebug("connection unstalled");
		    $wwatch[$to] = undef;
		    if ( ! $eof[$from] ) {
			$rwatch[$from] = AnyEvent->io(
			    fh => $fh[$from],
			    poll => 'r',
			    cb => $rcb[$from]
			);
		    }
		}
		if ( $eof[$from] and $rbuf[$from] eq '' ) {
		    # can shutdown write
		    $self->xdebug("shutdown $to,1");
		    shutdown($fh[$to],1);
		    $self->{expire} = AnyEvent->now + 5;
		}
	    }
	};
    }

    # set Net::IMP callback
    # ---------------------------------------------------------------------
    $imp and $imp->set_callback( sub {

	my @tosend; # new data in wbuf on non-stalled connections
	for my $rv (@_) {
	    my $rtype = shift(@$rv);
	    $self->xdebug( "$rtype @$rv");

	    if ( $rtype == IMP_DENY ) {
		# close connection
		my ($dir,$msg) = @$rv;
		# silent close if no msg
		# FIXME use smthg better then just debug
		$self->xdebug("connection denied: dir=$dir '$msg'") if $msg;
		&$close;
		return;

	    } elsif ( $rtype == IMP_FATAL ) {
		my $reason = shift;
		# FIXME use smthg better then just debug
		$self->xdebug("fatal error from analyzer: $reason");
		&$close;
		return;

	    } elsif ( $rtype == IMP_LOG ) {
		my ($dir,$offset,$len,$level,$msg) = @$rv;
		# FIXME use smthg better then just debug
		$self->xdebug("imp[$dir] off=$offset/$len <$level> $msg");

	    } elsif ( $rtype == IMP_ACCTFIELD ) {
		my ($key,$value) = @$rv;
		# FIXME use smthg better then just debug
		$self->xdebug("accounting $key=$value");

	    } elsif ( $rtype ~~ [ IMP_PASS, IMP_PREPASS ] ) {
		my ($dir,$offset) = @$rv;
		$self->xdebug("got $rtype $dir|$offset passed=$imp_passed[$dir]");

		my $len = length($rbuf[$dir]);  # how much to (pre)pass
		if ( $offset == IMP_MAXOFFSET ) {
		    if ( $imp_topass[$dir] == IMP_MAXOFFSET ) {
			next; # no change
		    } elsif ( $rtype == IMP_PASS ) {
			# extend topass
			$imp_topass[$dir] = IMP_MAXOFFSET;
		    } else {
			# extend toprepass
			$imp_toprepass[$dir] = IMP_MAXOFFSET;
		    }
		} else {
		    my $diff = $offset - $imp_passed[$dir];
		    if ( $diff < 0 ) {
			# already passed
			$self->xdebug("diff=$diff - $rtype for already passed data");
			next;
		    } elsif ( $diff>$len ) {
			$len = $diff
		    }
		    if ( $rtype == IMP_PASS ) {
			$imp_topass[$dir] = $offset;
		    } elsif ( $imp_topass[$dir] < $offset ) {
			$imp_toprepass[$dir] = $offset;
		    }
		}

		$self->xdebug("need to $rtype $len bytes");

		$imp_passed[$dir]  += $len;

		# forward data to wbuf of other side
		if ($len) {
		    my $to = $dir?0:1;
		    push @tosend,$to if $wbuf[$to] eq '';
		    $wbuf[$to] .= substr($rbuf[$dir],0,$len,'');
		}

	    } elsif ( $rtype == IMP_REPLACE ) {
		my ($dir,$offset,$newdata) = @$rv;
		die "cannot replace future data" if $offset == IMP_MAXOFFSET;
		my $diff = $offset - $imp_passed[$dir];
		die "cannot replace already passed data" if $diff<0;
		my $len = length($rbuf[$dir]);
		die "cannot replace future data" if $diff>$len;

		$self->xdebug("buf='%s' [0,$len]->'%s'",substr($rbuf[$dir],0,$len),$newdata);
		substr($rbuf[$dir],0,$len,$newdata);
		$imp_passed[$dir]  += $len;
		$len = length($newdata);

		# forward data to wbuf of other side
		if ($len) {
		    my $to = $dir?0:1;
		    push @tosend,$to if $wbuf[$to] eq '';
		    $wbuf[$to] .= substr($rbuf[$dir],0,$len,'');
		}

	    } elsif ( $rtype == IMP_TOSENDER ) {
		my ($dir,$data) = @$rv;
		# send data back to sender
		push @tosend,$dir if $wbuf[$dir] eq '';
		$wbuf[$dir] .= $data;

	    } elsif ( $rtype == IMP_PAUSE ) {
		# stop receiving data
		my $from = shift;
		undef $rwatch[$from];
	    } elsif ( $rtype == IMP_CONTINUE ) {
		# start receiving data again
		my $from = shift;
		$rwatch[$from] = AnyEvent->io(
		    fh => $fh[$from],
		    poll => 'r',
		    cb => $rcb[$from]
		);
	    } else {
		die "cannot handle Net::IMP rtype $rtype";
	    }
	}

	# output collected data
	while ( @tosend ) {
	    my $dir = shift(@tosend);
	    $wcb[$dir](1);
	}
    });

    # enable read handler on both sides
    # ---------------------------------------------------------------------
    for my $from (0,1) {
	$rwatch[$from] = AnyEvent->io(
	    fh => $fh[$from],
	    poll => 'r',
	    cb => $rcb[$from]
	);
    }

    return $self;
}

sub close:method {
    my $self = shift;
    $self->{closef}();
}

sub dump_state {
    my $self = shift;
    warn "to be done\n";
}

sub fatal {
    my ($self,$reason) = @_;
    $self->xdebug("fatal: $reason");
    $self->close;
}

sub xdebug {
    my $self = shift;
    my $msg  = shift;
    unshift @_,"[$self->{connid}] $msg";
    goto &debug;
}
