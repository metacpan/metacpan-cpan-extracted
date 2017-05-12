package Net::PSYC;
#
#		___   __  _   _   __ 
#		|  \ (__   \ /   /   
#		|__/    \   V   |    
#		|    (__/   |    \__ 
#
#	Protocol for SYnchronous Conferencing.
#	 Official API Implementation in PERL.
#	  See  http://psyc.pages.de  for further information.
#
# Copyright (c) 1998-2005 Carlo v. Loesch and Arne Goedeke.
# All rights reserved.
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself. Derivatives may not carry the
# title "Official PSYC API Implementation" or equivalents.
#
# Concerning UDP: No retransmissions or other safety strategies are
# implemented - and none are specified in the PSYC spec. If you use
# counters according to the spec you can implement your own safety
# mechanism best suited for your application.
#
# Status: the Net::PSYC is pretty much stable. Just details and features
# are being refined just as the protocol itself is, so from a software
# developer's point of view this library is quite close to a 1.0 release.
# After six years of development and usage that's presumably appropriate, too.

# last snapshot made when i changed this into 0.21  -lynX
our $VERSION = '0.21';

use strict;

our (%O, %C, %L, %MMPVARS);
our $ANACHRONISM = 0;
my ($UDP, $AUTOWATCH, %R, %hosts, %URLS);
my ($DEBUG, $NO_UDP, $STATE, $BLOCKING) = (0, 0, 0, 3);
# BLOCKING BITS
# 1 WRITE (contains CONNECT)
# 2 READ
#
# STATE BITS
# 0 <- no bit really, anyway: NO STATE AT ALL. this is not compliant to the
# PSYC protocol, should be used by scripts only.. dont send state-ful variables
# and dont plan to receive any messages!
# 1 RECEIVE/EMULATE STATE
# 2 AUTO-SEND STATE

sub FORK () { 0 }

%O = (
    # arrays suck
    '_understand_modules' => {  },
    '_understand_protocols' => 'PSYC/0.9 TCP IP/4, PSYC/0.9 UDP IP/4',
    '_implementation' => sprintf "Net::PSYC/%s perl/v%vd %s", $VERSION, $^V, $^O
);

%MMPVARS = (
    '_source'	=> 1,
    '_target'	=> 1,
    '_context'	=> 1,
    '_count'	=> 1,
    '_identification'	=> 1,
    '_source_relay'	=> 1,
    '_length'	=> 0,
    '_fragment'	=> 0,
    '_amount_fragments'	=> 0,
    '_using_modules'	=> 0,
    '_understand_modules'	=> 0,
);

sub ISMMPVAR { exists $MMPVARS{ ($_[0] =~ /^_/) ? $_[0] : substr($_[0], 1) } }
sub MERGEVAR { $MMPVARS{ ($_[0] =~ /^_/) ? $_[0] : substr($_[0], 1) } }

our @EXPORT = qw(bind_uniform psyctext make_uniform UNL sendmsg
	     dirty_add dirty_remove dirty_wait
	     parse_uniform dirty_getmsg); # dirty_getmsg is obsolete!

our @EXPORT_OK = qw(makeMSG parse_uniform $UDP %C PSYC_PORT PSYCS_PORT
		UNL W AUTOWATCH BLOCKING sendmsg bind_uniform make_uniform 
		psyctext BASE SRC DEBUG setBASE setSRC setDEBUG
		register_uniform make_mmp make_psyc parse_mmp parse_psyc
		send_mmp get_connection
		register_route register_host same_host dns_lookup
		psyctext _augment _diminish
		ISMMPVAR MERGEVAR W0 W1 W2 send_file);

 
sub PSYC_PORT () { 4404 }	# default port for PSYC
#sub PSYCS_PORT () { 9404 }	# non-negotiating TLS port for PSYC
 
my $BASE = '/'; # the UNL pointing to this communication endpoint 
                # with trailing / 
my $SRC = '';   # default sending object, without leading $BASE 
 
# inspectors, in form of inline macros 
sub BASE () { $BASE } 
sub SRC () { $SRC } 
sub UNL () { $BASE.$SRC } 
# settors 
sub setBASE { 
    $BASE = shift;
    unless ($BASE =~ /\/$/) {
	$BASE .= '/';
    }
    # its useful to register the host here since it may be dyndns
    register_host('127.0.0.1', parse_uniform($BASE)->{'host'});
} 
sub setSRC { $SRC = shift; } 

sub DEBUG () { $DEBUG }
sub setDEBUG { 
    $DEBUG = shift;
    W0('Debug Level %d set for Net::PSYC/%s.', $DEBUG, $VERSION);
}

# the "other" sub W should be used, but this one is .. TODO
sub W {
    my $line = shift;
    my $level = shift;
    $level = 1 unless(defined($level));
    print STDERR "\r$line\r\n" if DEBUG() >= $level;
}

sub SW {
    my $level = shift;
    return if DEBUG() < $level;
    my $f = shift;

    W(sprintf($f, @_), $level);    
}

sub W0 {
    return SW(0, @_); 
}

sub W1 {
    return SW(1, @_); 
}

sub W2 {
    return SW(2, @_); 
}

sub BLOCKING { 
    $BLOCKING = $_[0] if exists $_[0];
    return $BLOCKING;
}

sub STATE {
    $STATE = $_[0] if exists $_[0];
    return $STATE;
}

sub SSL () {
    return 1 if (eval{
	require IO::Socket::SSL;
	my $t = $IO::Socket::SSL::VERSION;
	$t =~ /(\d)\.(\d+)/ && $1 + (0.1**(length($t) - 2))*$2 >= 0.93
    });
}

use Socket qw(sockaddr_in inet_ntoa inet_aton);

# we have to find some solution for W. it really sux the way it is
print STDERR "Net::PSYC $VERSION loaded in debug mode.\n\n" if DEBUG;

#############
# Exporter..
sub import {
    my $pkg = caller();
    my $list = ' '.join(' ', @_).' ';
    $list =~ s/ W / W W0 W1 W2 /g;
    $list =~ s/Net::PSYC//g; # 
    if ($list =~ s/Event=(\S+) | :event | :nonblock / /) {
	my $match = $1; # the following require resets / unsets $1, at least
		        # some times.
	require Net::PSYC::Event; 
	Net::PSYC::Event::init($match ? $match : 'IO::Select');
	import Net::PSYC::Event qw(watch forget register_uniform 
				   unregister_uniform add remove 
				   can_read start_loop stop_loop revoke);
	push(@EXPORT_OK, qw(watch forget register_uniform 
				   unregister_uniform add remove 
				   can_read start_loop stop_loop revoke));
	export($pkg, qw(watch forget register_uniform unregister_uniform 
			revoke add remove can_read start_loop stop_loop));
	BLOCKING(0);
    } elsif ($list =~ s/ :anachronism / /) {
	require Net::PSYC::Event;
	unless (Net::PSYC::Event::init('IO::Select')) {
	    W0('Huh? What happened to IO::Select? %s', $!);
	    return 0;
	}
	#its not possible to do negotiation with getMSG.. or you do it yourself
	import Net::PSYC::Event qw(watch forget register_uniform 
				   unregister_uniform revoke add 
				   remove can_read start_loop stop_loop);
	push(@EXPORT_OK, qw(watch forget register_uniform 
				   unregister_uniform add remove 
				   can_read start_loop stop_loop revoke));
	export($pkg, qw(watch forget register_uniform unregister_uniform revoke
			add remove can_read start_loop stop_loop));
	export($pkg, @EXPORT);
	BLOCKING(1); # blocking WRITE
    }

    if ($list =~ s/ :tls | :ssl | :encrypt / /) {
	if (SSL) {
	    $O{'_understand_modules'}->{'_encrypt'} = 1;
	} else {
	    W0('You need IO::Socket::SSL to use _encrypt. require() said: %s', 
	       $!);   
	}
    }
    if ($list =~ s/ :zlib | :compress / /) {
	if (eval { require Net::PSYC::MMP::Compress }) {
	    $O{'_understand_modules'}->{'_compress'} = 1;
	} else {
	    W0('You need Compress::Zlib to use _compress. require() said: %s', 
		$!);   
	}
    }
    if ($list =~ s/ :fork / /) {
	eval qq {
	    sub FORK { 1 }
	};
    }

    return export($pkg, @EXPORT) unless ($list =~ /\w/);
    
    if ($list =~ / :all /) {
	export($pkg, @EXPORT);
	export($pkg, @EXPORT_OK);
    } elsif ($list =~ / :base /) {
	export($pkg, @EXPORT);
    }
    
    my @subs = grep { $list =~ /$_/ } @EXPORT_OK;
    if (scalar(@subs)) {
        export($pkg, @subs);
    }
    
}

#   export(caller, list);
sub export {
    my $pkg = shift;
    no strict "refs";
    foreach (@_) {
	W2('exporting %s to %s', $_, $pkg);
	# 'stolen' from Exporter/Heavy.pm
	if ($_ =~ /^([$%@*&])/) {
	    *{"${pkg}::$_"} =
		$1 eq '&' ? \&{$_} :
		$1 eq '$' ? \${$_} :
		$1 eq '@' ? \@{$_} :
		$1 eq '%' ? \%{$_} : *{$_};
	    next;
	} elsif ($_ =~ /^\>(\w+)/) {
	    *{$1} = *{"${pkg}::$1"};
	} else {
	    *{"${pkg}::$_"} = \&{$_};
	    
	}
    }
}
#
##############
##############
# DNS
#   register_route ( ip|ip:port|target, connection )
sub register_route {
    W2('register_route(%s, %s)', $_[0], $_[1]);
    $R{$_[0]} = $_[1];
}

#   register_host (ip, hosts)
#   TODO : this is still not very efficient.. 2-way hashes would be very nice
sub register_host {
    my $ip = shift;
    if (exists $hosts{$ip}) {
	$ip = $hosts{$ip};
    } else {
	$hosts{$ip} = $ip;
    }
    W2('register_host(%s, %s)', $ip, join(", ", @_));
    foreach (@_) {
	$hosts{$_} = $ip;
	foreach my $host (keys %hosts) {
	    if ($hosts{$host} eq $_) {
		$hosts{$host} = $ip;
	    }
	}
    }
}

sub dns_lookup {
    my $name = shift;
    my $callback = shift;

    if ($name =~ /\d+\.\d+\.\d+\.\d+/) {
	return $callback->($name) if $callback;
	return $name;
    }
    my $addr = gethostbyname($name);
    if ($addr) {
	my $ip = join('.', (unpack('C4', $addr)));
	W2('dns_lookup(%s) == %s', $name, $ip);
	register_host($ip, $name);
	return $callback->($ip) if $callback;
	return $ip;
    } else { 
	return $callback->(0) if $callback;
	return 0; 
    }
}

sub same_host {
    my ($one, $two, $callback) = @_;
    W2('same_host(%s, %s)', $one, $two);
    if (($one && $two) && (exists $hosts{$one} || dns_lookup($one)) && (exists $hosts{$two} || dns_lookup($two))) {
	if ($callback) {
	    return $callback->($hosts{$_[0]} eq $hosts{$_[1]});
	}
	return $hosts{$_[0]} eq $hosts{$_[1]};	
    }
    $callback->(0) if ($callback);
    return 0;
}
#
##############
##############
#
sub use_modules {
    foreach (@_) {
	unless (/_state|_encrypt|_compress|_fragments|_length|_context/) {
	    W0('No suchs MMP module: %s', $_);
	}
	$O{'_understand_modules'}->{$_} = 1;
    }
}
#
##############

sub bind_uniform {
    my $source = shift || 'psyc://:/'; # get yourself any tcp and udp port
#   $source or croak 'usage: bind_uniform( $UNI )';
    
    my ($user, $host, $port, $prots, $object) = parse_uniform($source);
    my ($ip, $return);

    
    register_host('127.0.0.1', $host) if ($host);
    
    if (!$prots || $prots =~ /d/oi) { # bind a datagram
	require Net::PSYC::Datagram;
	my $sock = Net::PSYC::Datagram->new($host, $port);
	if (ref $sock) {
	    $UDP = $sock;
	    $return = $UDP;
	    $port = $return->{'PORT'};
	} else {
	    W0('UDP bind to %s:%s failed: %s', $host, $port, $sock);
	}
    }
    if (!$prots || $prots =~ /c/oi) { # bind a circuit
	require Net::PSYC::Circuit;
	my $sock = Net::PSYC::Circuit->listen($host, $port, \%O);
	if (ref $sock) {
	    $host ||= $sock->{'IP'};
	    $port = $sock->{'PORT'};
	    $L{$host.':'.$port} = $sock;
	    # tcp-sockets watch themselfes
	    $return = $L{$host.':'.$port};
	    $port = $return->{'PORT'};
	} else {
	    W0('TCP bind to %s:%s failed: %s', $host, $port, $sock);
	}
    }
    if ($prots && $prots =~ /s/oi) { # bind an SSL
	die "We don't allow binding of SSL sockets because SSL should".
	    " be negotiated anyway";
    }
    return unless ($return);
    # how does one check for fqdn properly?
    # TODO $ip is undef !
    my $unlhost = $host =~ /\./ ? $host : $ip || '127.0.0.1';
    warn 'Could not find my own hostname or IP address!?' unless $unlhost;
    
    $SRC = $object;
    $BASE = &make_uniform($user, $unlhost, $port, $prots);
    W1('My UNL is %s%s', $BASE, $SRC);
    return $return if (defined wantarray);
}

# shutdown a connection-object.. 
sub shutdown {
    my $obj = shift;
    forget($obj); # stop delivering packets ..
    $obj->{'SOCKET'}->close() if ($obj->{'SOCKET'});
    foreach (keys %C) {
	delete $C{$_} if ($C{$_} eq $obj);
    }
    foreach (keys %R) {
	delete $R{$_} if ($R{$_} eq $obj);
    }
}

#   get_connection ( target )
sub get_connection {
    my $target = shift;

    my ($user, $host, $port, $prots, $object) = parse_uniform($target);

    unless (defined $user) {
	return 0;
    }
    # hm.. irgendwo müssen wir aus undef 4404 machen.. 
    # goto sucks.. i will correct that later!   -elridion
    # goto rocks.. please keep it.. i love goto  ;-)   -lynX 
    #
    if ( !$prots || $prots =~ /c/i ) { # TCP
	$port ||= PSYC_PORT;
	goto TCP; 
    } elsif ( $prots =~ /d/i ) { # UDP
	$port ||= PSYC_PORT;
	goto UDP;
    } elsif ( $prots =~ /s/i ) {
	$port ||= PSYCS_PORT();
	goto TCP;
    } else { # AI
	goto TCP;
#	if (!$NO_UDP) {
#	    goto UDP;
#	} else { # TCP
#	    goto TCP;
#	}
    }
    TCP:
    require Net::PSYC::Circuit;
    my @addresses = gethostbyname($host);
    if (@addresses > 4) {
	$host = inet_ntoa($addresses[4]);
    }
    if (exists $C{$host.':'.$port}) { # we have a connection
	return $C{$host.':'.$port};
    }
    if ($R{$target} || $R{$host.':'.$port} || $R{$host}) {
	return $R{$target} || $R{$host.':'.$port} || $R{$host};
    }
    require Net::PSYC::Circuit;
    $C{$host.':'.$port} = Net::PSYC::Circuit->connect($host, $port, \%O);
    return $C{$host.':'.$port};
    
    UDP:
    unless ($UDP) {
	require Net::PSYC::Datagram;
	$UDP = Net::PSYC::Datagram->new;
    }
    return $UDP;

}

#   sendmsg ( target, mc, data, vars[, source || MMP-vars] )
sub sendmsg {
    my ($MMPvars, $state);
    goto FIRE if (!STATE() && BLOCKING() & 2);

    if (ref $_[0]) { # this is a $self->sendmsg
	#hmm
	$state = shift;
	$MMPvars = $_[4];
	$MMPvars = { '_source' => $MMPvars } if ($MMPvars && !ref $MMPvars);
    } else {
	# now we try to find out who you are.
	$MMPvars = $_[4];
	$MMPvars = { '_source' => $MMPvars } if ($MMPvars && !ref $MMPvars);
	if (exists $MMPvars->{'_source'}) {
	    $state = Net::PSYC::Event::unl2wrapper($MMPvars->{'_source'});
	}
	unless ($state) {
	    $state = caller(); 
	    $state = Net::PSYC::Event::unl2wrapper($state);
	}

    }
    FIRE:

    my ($target, $mc, $data, $vars) = @_;
    $target or die 'usage: sendmsg( $UNL, $method, $data, %vars )';

    unless ($MMPvars) {
	$MMPvars = {};
    } elsif (!ref $MMPvars) {
	$MMPvars = { '_source' => $MMPvars };
    }

    $MMPvars->{'_target'} ||= $target;
    
    my $connection = get_connection( $target );

    # TODO do a retry here in case we have nonblocking writes!
    # also. catch the return-error and make a W. we want no murks
    return 'SendMSG failed: '.$connection if (!ref $connection); 
    my $d = make_psyc( $mc, $data, $vars, $state, $target);
    return $connection->send( $target, $d, $MMPvars );   
}

#   send_mmp (target, data, vars)
sub send_mmp {
    my ( $target, $data, $vars ) = @_;
    
    # maybe we can check for the caller of sendmsg and use his unl as
    # source.. TODO ( works with Event only ). stone perloo
    $target or die 'usage: send_mmp( $UNL, $MMPdata, %MMPvars )';
    #
    # presence of a method or data is not mandatory:
    # a simple modification of a variable may be sent as well,
    # although that only starts making sense once _state is implemented.
    if ($vars) {
	$vars->{'_target'} ||= $target;
    } else {
	$vars = { _target => $target };
    }
    
    my $connection = get_connection( $target );
    return 0 if (!$connection);
    return $connection->send( $target, $data, $vars );
}

# send a file. this one is very straightforward.. may kill the other sides 
# perlpsyc by sending huge files at once. 
sub send_file {
    my ( $target, $fn, $vars, $offset, $length ) = @_;

    return 0 unless (-e $fn);
    my (@file);

    require Net::PSYC::Tie::File unless (%Net::PSYC::Tie::File::);

    # 1024 is maybe too small. we should think about making
    # that dependend on the bandwidth
    my $o = tie @file, 'Net::PSYC::Tie::File', $fn, 6024, int($offset), 
		int($length) 
	or return 0;

    # set all vars to proper values.
    $offset = $o->{'OFFSET'};
    $vars->{'_seek_resume'} = $offset if $offset;
    $vars->{'_size_file'} = $o->{'SIZE'};

    if ($length) {
	$length = $o->{'RANGE'};
	$vars->{'_size_resume'} = $o->{'RANGE'}; 
	$vars->{'_size_file'} = $o->{'SIZE'};
    } else {
	$length = $o->{'SIZE'};
	$vars->{'_size_file'} = $length;
    }
    $vars->{'_name_file'} ||= substr($fn, rindex($fn, '/')+1);
    my $header;
    # looks stupid to first create the hash and then run through it again.
    foreach my $key (keys %$vars) {
	my $mod = substr($key, 0, 1);
	if ($mod ne '_') {
	    $key = substr($key, 1);
	} else {
	    $mod = ':';
	}

	$header .= make_header($mod, $key, $vars->{$key}) unless ISMMPVAR($key); 
    }

    # new undocumented feature. sets _length to the apropriate value ..
    $vars->{'_length'} = undef;

    # one should not forget about known errors. maybe i should carry a little
    # notebook to keep track of things that come to my mind while i am not
    # at my comp
    unshift @file, $header."_data_file\n";
    
    return !send_mmp($target, \@file, $vars);
}

sub psyctext {
    my $text = shift;
    $text =~ s/\[\?\ (_\w+)\](.+?)\[\;\]/(exists $_[0]->{$1}) ? $2 : ""/ge;
    $text =~ s/\[\?\ (_\w+)\](.+?)\[\:\](.+?)\[\;\]/(exists $_[0]->{$1}) ? $2 : $3/ge;
    $text =~ s/\[\!\ (_\w+)\](.+?)\[\;\]/(!exists $_[0]->{$1}) ? $2 : ""/ge;
    $text =~ s/\[\!\ (_\w+)\](.+?)\[\:\](.+?)\[\;\]/(!exists $_[0]->{$1}) ? $2 : $3/ge;
    $text =~ s/\[(_\w+)\]/my $ref = ((exists $_[0]->{$1}) ? $_[0]->{$1} : ''); (ref $ref eq 'ARRAY') ? join(' ', @$ref) : $ref;/ge;
    return $text;
}

sub parse_mmp {
    use bytes;
    my $d = shift;
    my $lf = shift;
    my $o;
    if (ref $lf) {
	$o = $lf;
	$lf = "\n";
    } else {
	$o = shift;
	$lf ||= "\n";
    }
    $lf ||= "\n";

    my $l = length($lf);

    my $vars = {}; 
    my $ref;
    if (ref $d eq 'SCALAR') {
	$ref = 1;
    } else {
	$d = \$d;
    }

    my $length;
    my ($a, $b) = ( 0, 0 );
    my ($lmod, $lvar, $lval, $data);

    # TODO. stop checking for $data, use last instead.
    # maybe
    LINE: while (!defined($data) && $a < length($$d) && 
           -1 != ($b = index($$d, $lf, $a))) {
	my $line = substr($$d, $a, $b - $a);	       
	my ($mod, $var, $val);

	#W1("parse_mmp: '$line'");

	# TODO put that into _one_ regexp
	if ($line =~ /^([+-:=-?])(_\w+)[\t\ ](.*)$/ ||
	    $line =~ /^([+-:=-?])(_\w+)$/) {
	    ($mod, $var, $val) = ($1, $2, $3);
	    #W0('mod: %s, var: %s, val: %s', $mod, $var, $val);
	    $length = int($val) if ($var eq '_length');

	} elsif ($line eq '') {
	    if ($length) {
		if (length($$d) < $b + $length + 2*$l) {
		    # return amount of bytes missing
		    return length($$d) - $b - $length - 2*$l; 
		}
		
		unless ("$lf.$lf" eq substr($$d, $b + $l + $length, 2*$l + 1)) {
		    return (0, "The _length specified does not match the packet.");
		}
		$length += $b+$l;
	    } elsif (".$lf" eq substr($$d, $b+$l, 1+$l)) {
		# the 2. variant of a mmp-packet without data
		substr($$d, 0, $b+$l*2+1 , ''); 
		$data = '';
	    } else {
		$length = index($$d, "$lf.$lf", $b+$l);
		# means: the packet is incomplete. we have to do something
		# about too long packets! TODO
		return if ($length == -1);
	    }

	    unless (defined $data) {
		$data = substr($$d, 0, $length + 2*$l + 1, '');
		$data = substr($data, $b + $l, $length - $b - $l);
	    }
	} elsif ($line eq '.') { 
	    # packet stops here. means we have no data
	    substr($$d, 0, $b + $l, '');
	    $data = '';
	} elsif ($line =~ /^([+-:=-?])[\t\ ](.*)$/) {
	    if (!$lmod) {
		return (0, "Lonesome list continuation.");
	    } elsif ($1 ne $lmod) {
		return (0, "Mixed modifiers in list continuation.");
	    } elsif ($1 eq '-') {
		return (0, "Diminish of a list.");
	    } elsif (!$lval) {
		return (0, "Empty variable in list.");
	    }
	    if (ref $lval eq 'ARRAY') {
		push(@$lval, $2);
	    } else {
		$lval = [ $lval, $2 ];
	    }

	    goto NEXT;
	} elsif ($line =~ /^\t(.*)$/) {
	    unless ($lval) {
		# raise an error here!
		return (0, "Lonesome variable continuation.");
	    }
	    $lval .= $1; 
	    goto NEXT;
	} else {
	    return (0, "I cannot parse that line: '$line'");
	}

	if ($lvar) {
	    if ($lmod eq ':') {
		$vars->{$lvar} = $lval;
	    } elsif (ref $o) {
		# TODO maybe its even better to use an hash instead of an
		# object. i cannot imagine a case in which the flexibility
		# of a funcall is needed. even if there was one, a tied hash
		# would do the trick
		if ($lmod eq '=') {
		    $o->assign($lvar, $lval);
		} elsif ($lmod eq '+') {
		    $o->augment($lvar, $lval);
		} elsif ($lmod eq '-') {
		    $o->diminish($lvar, $lval);
		}
	    } else {
		$vars->{$lmod.$lvar} = $lval;
	    }

	    $vars->{$lvar} = $lval if ($lmod eq '=');
	}

	($lmod, $lvar, $lval) = ($mod, $var, $val);
NEXT:
	$a = $b + $l;
    }
    # er. i dont know yet. check that TODO
    return unless defined $data;
    return ($vars, $data);
}

sub parse_psyc {

    my $d = shift;
    $d = $$d if (ref $d eq 'SCALAR');

    my $linefeed = shift;
=state
    my $o;
    if (ref $linefeed) {
	$o = $linefeed;
	$linefeed = "\n";
    } else {
	$linefeed ||= "\n";
	$o = shift;
    }
    my $iscontext = shift;
    my $source = shift;
=cut
    $linefeed ||= "\n";

    my ($mc, $data, $vars) = ( '', '', {} );
    my ($a, $b) = (0, 0); # the interval we are parsing
    my ($lmod, $lvar, $lval);

    while (!$mc && $a < length($d) && 
		 (-1 != ($b = index($d, $linefeed, $a)) || ($b = length($d)))) {
	my $line = substr($d, $a, $b - $a);
	#W1('line: "%s"', $line);
	my ($mod, $var, $val);

	# this could be combined .. TODO
	if ($line =~ /^([+-:=-?])(_\w+)[\t\ ](.*)$/ ||
	    $line =~ /^([+-:=-?])(_\w+)$/) {
	    ($mod, $var, $val) = ($1, $2, $3);
	    $val = [ $val ] if ($var =~ /^_list/);
	} elsif ($line =~ /^([+-:=-?])[\t\ ](.*)$/) {
	    if (!$lmod) {
		return (0, "Lonesome list continuation.");
	    } elsif ($1 ne $lmod) {
		return (0, "Mixed modifiers in list continuation.");
	    } elsif ($1 eq '-') {
		return (0, "Diminish of a list.");
	    } elsif (!$lval) {
		return (0, "Empty variable in list.");
	    }
	    if (ref $lval eq 'ARRAY') {
		push(@$lval, $2);
	    } else {
		$lval = [ $lval, $2 ];
	    }

	    goto NEXT;
	} elsif ($line =~ /^\t(.*)$/) {
	    unless ($lvar) {
		# raise an error here!
		return (0, "Lonesome variable continuation.");
	    }
	    $lval .= "\n".$1; 
	    goto NEXT;
	    # variable continuation
	} elsif ($line =~ /^(_\w+)$/) {
	    $mc = $1;
	    $mc =~ s/^(?:_talk|_conversation|_converse)/_message/;
	} else {
	    return (0, "Could not parse: '".$line."'");
	}

	if ($lvar) {
	    if ($lvar =~ /^_list/ && ref $lval ne 'ARRAY') {
		$lval = [ $lval ];
	    }
	    if ($lmod eq ':') {
		$vars->{$lvar} = $lval;
=state
	    } elsif (ref $o) {
		# TODO same as above. I will change that. 
		if ($lmod eq '=') {
		    $o->assign($lvar, $lval, $source, $iscontext);
		} elsif ($lmod eq '+') {
		    $o->augment($lvar, $lval, $source, $iscontext);
		} elsif ($lmod eq '-') {
		    $o->diminish($lvar, $lval, $source, $iscontext);
		}
=cut
	    } else {
		$vars->{$lmod.$lvar} = $lval;
	    }
	    $vars->{$lvar} = $lval if ($lmod eq '=');
	}

	($lmod, $lvar, $lval) = ($mod, $var, $val);
NEXT: 
	$a = $b+length($linefeed);
    }

    return (0, "Method is missing.") unless ($mc);
	
    $d = substr($d, $a);

    return ($mc, $d, $vars);
}

sub make_header {
    my ($mod, $key, $val) = @_;
    my $m;
    
    unless (defined($val)) {
	$m = '';
    } elsif (ref $val eq 'ARRAY') {
	$m = "\t".join("\n$mod\t", @$val); 
    } else {
	$val =~ s/\n/\n\t/g;
	$m = "\t$val";
    }
    return "$mod$key$m\n";
}

sub make_mmp {
    use bytes;
    # $state is an object implementing out-state and state.. blarg
    my ($vars, $data, $state) = @_;
    my $m;
    
    if (!exists $vars->{'_length'}) {
	$vars->{'_length'} = length($data) 
	    if ($data =~ /^.\n/ || index($data, "\n.\n") != -1 || 
		index($data, "\r\n.\r\n") != -1);
    } elsif (!defined($vars->{'_length'})) {
	$vars->{'_length'} = length($data);
    }
    
    # we dont need to sort anymore. _count is a mmp-var. CHANGE THAT TODO
    foreach (sort keys %$vars) {
	my $mod = substr($_, 0, 1);
	my $var = $_;
	
	if ($mod ne '_') {
	    $var = substr($_, 1);
	} else { $mod = ':'; }

	$m .= make_header($mod, $var, $vars->{$_}) if ISMMPVAR($var); 
=state
	    if (ISMMPVAR($var) && 
	    (!$state || $state->outstate($mod, $var, $vars->{$_})));
=cut
    }
=state
    if ($state) {
	my $v = $state->state();
	
	foreach (keys %$v) {
	    $m .= make_header(':', $_, $v->{$_});
	}
    }
=cut

    if (!$data) {
	$m .= ".\n";
    } else {
	$m .= "\n$data\n.\n";
    }
    return $m;
}

#   make_psyc ( mc, data, vars)
sub make_psyc {
    my ($mc, $data, $vars, $state, $target, $iscontext) = @_;
    my $m = "";

    # we dont need to sort anymore. _count is a mmp-var. CHANGE THAT TODO
    foreach (sort keys %$vars) {
	my $mod = substr($_, 0, 1);
	my $var = $_;

	next if ($var =~ /^_INTERNAL_/);
	
	if ($mod ne '_') {
	    $var = substr($_, 1);
	} else { $mod = ':'; }

	$m .= make_header($mod, $var, $vars->{$var}) unless ISMMPVAR($var);
=state
	    if (!ISMMPVAR($var) && 
	    (!$state || $state->outstate($mod, $var, $vars->{$var}, $target, 
					 $iscontext)));
=cut
    }
=state
    if ($state) {
	my $v = $state->state($target, $iscontext);
	
	foreach (keys %$v) {
	    $m .= make_header(':', $_, $v->{$_});
	}
    }
=cut

    $m .= $mc;
    $m .= "\n" if ($m && $data);
    return $m.($data || '');
}

sub _augment {
    my ($vars, $key, $value) = @_;

    if (ref $value eq 'ARRAY') {
	# TODO ..
	map { _augment($vars, $key, $_) unless (ref $_) } @$value;
	return 1;
    }

    unless (exists $vars->{$key}) {
        $vars->{$key} = [ $value ];
    } elsif (ref $vars->{$key} ne 'ARRAY') {
        $vars->{$key} = [ $vars->{$key}, $value ];
    } else {
        push(@{$vars->{$key}}, $value);
    } 
    return 1;
}

sub _diminish {
    my ($vars, $key, $value) = @_;

    return if (not exists $vars->{$key});

    if (ref $vars->{$key} ne 'ARRAY') {
	delete $vars->{$key} if ($vars->{$key} eq $value);
    } else {
	@{$vars->{$key}} = grep { $_ ne $value } @{$vars->{$key}};
    }
}

# TODO rename that to make_msg.
# replaced by make_psyc
sub makeMSG { 
    my ($mc, $data) = @_;
    my $vars = $_[2] || {};
    
    return ($vars, make_psyc($mc, $data, $vars)) if wantarray;

    return make_mmp($vars, make_psyc($mc, $data, $vars));
}

sub parse_uniform {
    my $arg = shift;

    if (exists $URLS{$arg}) {
	my $t = $URLS{$arg};
	return $t unless wantarray;
	
	return ( $t->{'user'}, $t->{'host'}, $t->{'port'}, $t->{'transport'}, 
		 $t->{'object'} );
    }
    local $_;
    $_ = $arg;

    my ($scheme, $user, $host, $port, $transport, $object);

    return $URLS{$arg} = 0 unless s/^(\w+)\://;
    $scheme = $1;
    
    if ($scheme eq 'psyc' || $scheme eq 'irc') {
	return $URLS{$arg} = 0 unless s/^\G\/\///;
    }

    if (s/([\w\-+]+)\@//) {
	$user = $1;
    } elsif ($scheme eq 'mailto' || $scheme eq 'xmpp') {
	# need a users..
	return $URLS{$arg} = 0;
    }

    # [\w-.] may be to restrictive. is it??
    return $URLS{$arg} = 0 unless s/^([\w\-.]*)(?:\:\-?(\d*)([cd]?)|)(?:\z|\/)//; 
    ($host, $port, $transport) = ($1, $2 ? int($2) : '', $3);

    # is there any other protocol supporting transports?? am i wrong here?
    return $URLS{$arg} = 0 if ($transport && $scheme ne 'psyc');

    goto EOU unless length($_);
    
    if ($scheme eq 'mailto') {
	# mailto should not have a path. what do we do then?
	return $URLS{$arg} = 0;	
    }

    return $URLS{$arg} = 0 unless ($scheme ne 'psyc' || /^[@~][\w\-]+$/);
    $object = $_;

EOU:
    return ($user||'', $host||'', $port, $transport||'', $object||'') 
	if wantarray;
    $URLS{$arg} = {
	unl => $arg,
	host => $host||'',	
	port => $port,
	transport => $transport||'',
	object => $object||'',
	user => $user||'',
	scheme => $scheme||'',
    };
    # maybe a cache is the best solution we got since tied scalars are not 
    # what I would like them to be.
    return $URLS{$arg};
}

# TODO i would like to get rid of croak. 
sub make_uniform {
        my ($user, $host, $port, $type, $object) = @_;
        $port = '' if !$port || $port == PSYC_PORT;
	unless ($object) {
	    $object = '';
	} else {
	    $object = '/'.$object;
	}
	
        $type = '' unless $type;
        unless ($host) {
		# we could check here for $Net::PSYC::Client::SERVER_HOST
                W0('well-known UNIs not standardized yet');
		return 0;
        }
        $host = "$user\@$host" if $user;
        return "psyc://$host$object" unless $port || $type;
        return "psyc://$host:$port$type$object";
}

################################################################
# Functions needed to be downward compatible to Net::PSYC 0.7
# Not entirely clear which of these we can really call obsolete
# 
sub dirty_wait {
    return Net::PSYC::Event::can_read(@_);
}
#
sub dirty_add {
    Net::PSYC::Event::add($_[0], 'r', sub { 1 }); 
}
sub dirty_remove { Net::PSYC::Event::remove(@_); }
#
# alright, so this should definitely not be used as it will not
# be able to handle multiple and incomplete packets in one read operation.
sub dirty_getmsg {
    my $key;
    my @readable = Net::PSYC::Event::can_read(@_);
    my %sockets = %{&Net::PSYC::Event::PSYC_SOCKETS()};
    my ($mc, $data, $vars);
    SOCKET: foreach (@readable) {
	$key = fileno($_);
	if (exists $sockets{$key}) { # found a readable psyc-obj
	    unless (defined($sockets{$key}->read())) {
		Net::PSYC::shutdown($sockets{$key});
		W2('Lost connection to %s:%s.', 
		    $sockets{$key}->{'R_IP'}, $sockets{$key}->{'R_PORT'});
		next SOCKET;
	    }
	    while (1) {
		my ($MMPvars, $MMPdata) = $sockets{$key}->recv();
		next SOCKET if (!defined($MMPdata));
		
		($mc, $data, $vars) = parse_psyc($MMPdata, $sockets{$key}->{'LF'});	
		last if($mc); # ignore empty messages..
	    }
	    W1('\n=== dirty_getmsg %s\n%s\n%s\n', '=' x 67, $data, '=' x 79);
	    my ($port, $ip) = sockaddr_in($sockets{$key}->{'LAST_RECV'})
		if $sockets{$key}->{'LAST_RECV'};
	    $ip = inet_ntoa($ip) if $ip;
	    return ('', $ip, $port, $mc, $data, %$vars);
	    return ('', '', 0, $mc, $data, %$vars);
	}
    }
    return ('NO PSYC-SOCKET READABLE!', '', 0, '', '', ());
}
#
################################################################


1;

# dirty_add, dirty_remove and dirty_wait implement a pragmatic IO::Select wrapper for applications that do not need an event loop.

__END__

=head1 NAME

Net::PSYC - Implementation of the Protocol for SYnchronous Conferencing.

=head1 DESCRIPTION

PSYC is a flexible text-based protocol for delivery of data to a flexible
amount of recipients by unicast or multicast TCP or UDP. It is primarily
used for chat conferencing, multicasting presence, friendcasting, newscasting,
event notifications and plain instant messaging, but not limited to that.

Existing systems can easily use PSYC, since PSYC hides its complexity from
them. For example if an application wants to send data to one person or a
group of people, it just needs to drop a few lines of text into a TCP
connection (or UDP packet) to a static address. In other words: trivial.

The PSYC network resembles more the Web rather than IRC, which it once was
inspired by. Each administrator of a machine on the Internet can install a
PSYC server which has equal rights in the world wide network. No hierarchies,
no boundaries. The administrator then has the right to decide which rooms or
people to host, without interfering with other PSYC servers. Should an
administrator behave incorrectly towards her users, they will simply move on
to a different server. Thus, administrators must behave to be a popular PSYC
host for their friends and social network.

This implementation is pretty stable and has been doing a good job in
production environments for several years.

See http://psyc.pages.de for protocol specs and other info on PSYC.

=head1 SYNOPSIS

Small example on how to send one single message:

    use Net::PSYC;
    sendmsg('psyc://example.org/~user', '_notice_whatever', 
	    'Whatever happened to the 80\'s...');

Receiving messages:

    use Net::PSYC qw(:event bind_uniform); 
    register_uniform(); # get all messages
    bind_uniform(); # start listening on :4404 tcp and udp.

    start_loop(); # start the Event loop

    sub msg {
	my ($source, $mc, $data, $vars) = @_;
	print "A message ($mc) from $source reads: '$data'\n";
    }    

=head1 PERL API

=over 4

=item bind_uniform( B<$localpsycUNI> )

starts listening on a local hostname and TCP and/or UDP port according to the PSYC UNI specification. When omitted, a random port will be chosen for both service types. 

=item sendmsg( B<$target>, B<$mc>, B<$data>, B<$vars> )

sends a PSYC packet defined by mc, data and vars to the given target. data and vars may be left out. bind_uniform() is not necessary to send PSYC packets. 

=item castmsg( B<$context>, B<$mc>, B<$data>, B<$vars> )

is NOT available yet. Net::PSYC does not implement neither context masters nor
multicasting. if you need to distribute content to several recipients please
allocate a context on a psycMUVE and sendmsg to it.

=item send_mmp( B<$target>, B<$data>, B<$vars> )

sends an MMP packet to the given B<$target>. B<$data> may be a reference to an array of fragmented data. 

=item psyctext( B<$format>, B<$vars> )

renders the strings in B<$vars> into the B<$format> and returns the resulting text conformant to the text/psyc content type specification. compatible to psycMUVEs psyctext. 

=item make_uniform( B<$user>, B<$host>, B<$port>, B<$type>, B<$object> )

Renders a PSYC uniform specified by the given elements. It basically produces: "psyc://$user@$host:$port$type/$object"

=item UNL()

returns the current complete source uniform.
UNL stands for Uniform Network Location.

=item setDEBUG( B<$level> )

Sets B<$level> of debug:

0 - no debug, only critical errors are reported

1 - some

2 - a lot (even incoming/outgoing packets)

=item DEBUG()

returns the current level of debug.

=item WB<$level>( B<$formal>, B<@vars> )

W() is used internally to print out debug-messages depending on the level of debug. You may want to overwrite this function to redirect output since the default is STDERR which can be really fancy-shmancy.

=item dns_lookup( B<$host> )

Tries to resolve B<$host> and returns the ip if successful. else 0.

Take care, dns_lookup is blocking. Maybe I will try to switch to nonblocking dns in the future.

=item same_host( B<$host1>, B<$host2> )

Returns 1 if the two hosts are considered identical. 0 else. Use this function instead of your own dns_lookup magic since hostnames are cached internally.

=item register_host( B<$ip>, B<$host> )

Make B<$host> point to B<$ip> internally.

=item register_route( B<$target>, B<$connection> )

From now on all packets for B<$target> are send via B<$connection> (Net::PSYC::Circuit or Net::PSYC::Datagram). B<$target> may be a full URL or of format host[:port].

=back

=head1 Export

Apart from the shortcuts below every single function may be exported seperately. You can switch on Eventing by using 

    use Net::PSYC qw(Event=IO::Select); 
    # or
    use Net::PSYC qw(Event=Gtk2);
    # or
    use Net::PSYC qw(Event=Event); # Event.pm

=over 4

=item use Net::PSYC qw(:encrypt);

Try to use ssl for tcp connections. You need to have L<IO::Socket::SSL> installed. Right now only tls client functionality works. Works with psycMUVE. 

=item use Net::PSYC qw(:compress);

Use L<Compress::Zlib> to compress data sent via tcp. Works fine with Net::PSYC and psycMUVE.

=item use Net::PSYC qw(:event);

:event activates eventing (by default IO::Select which should work on every system) and exports some functions (watch, forget, register_uniform, unregister_uniform, add, remove, start_loop, stop_loop) which are useful in that context. Have a look at L<Net::PSYC::Event> for further documentation.

=item use Net::PSYC qw(:base);

exports bind_uniform, psyctext, make_uniform, UNL, sendmsg, dirty_add, dirty_remove, dirty_wait, parse_uniform and dirty_getmsg.

=item use Net::PSYC qw(:all);

exports makeMSG, parse_uniform, PSYC_PORT, PSYCS_PORT, UNL, W, AUTOWATCH, sendmsg, make_uniform, psyctext, BASE, SRC, DEBUG, setBASE, setSRC, setDEBUG, register_uniform, make_mmp, make_psyc, parse_mmp, parse_psyc, send_mmp, get_connection, register_route, register_host, same_host, dns_resolve, start_loop, stop_loop and psyctext.

=back

=head1 Eventing

See Net::PSYC::Event for more.

For further details.. Use The Source, Luke!

=head1 SEE ALSO

L<Net::PSYC::Event>, L<Net::PSYC::Client>, L<http://psyc.pages.de> for more information about the PSYC protocol, L<http://muve.pages.de> for a rather mature PSYC server implementation (also offering IRC, Jabber and a Telnet interface) , L<http://perlpsyc.pages.de> for a bunch of applications using Net::PSYC.

=head1 AUTHORS

=over 4

=item Carlo v. Loesch

L<psyc://psyced.org/~lynX>
L<http://symlynX.com/>

=item Arne GE<ouml>deke

L<psyc://psyced.org/~el>
L<http://www.lionmen.de/>

=back

=head1 COPYRIGHT

Copyright (c) 1998-2005 Carlo v. Loesch and Arne GE<ouml>deke. All rights reserved.

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself. Derivatives may not carry the
title "Official PSYC API Implementation" or equivalents.

