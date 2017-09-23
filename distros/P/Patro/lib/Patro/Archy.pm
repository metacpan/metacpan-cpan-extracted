package Patro::Archy;
use strict;
use warnings;
use Carp;
eval "use Sys::HostAddr";
use Socket ();
use Scalar::Util 'reftype';
use POSIX ':sys_wait_h';
require overload;

our $threads_avail;
*sxdiag = sub {};
if ($ENV{PATRO_SERVER_DEBUG}) {
    *sxdiag = *::xdiag;
    our $DEBUG = 1;
}
our $VERSION = '0.15';
our @SERVERS :shared;
our %OPTS = ( # XXX - needs documentation
    keep_alive => 30,
    idle_timeout => 30,
    fincheck_freq => 5,
);

sub new {
    my $pkg = shift;
    my $opts = shift;

    my $host = $ENV{HOSTNAME} // qx(hostname) // "localhost";
    if ($INC{'Sys/HostAddr.pm'}) {
	my $host2 = Sys::HostAddr->new->main_ip;
	$host = $host2 if $host2;
    }
    chomp($host);

    socket(my $socket, Socket::PF_INET(), Socket::SOCK_STREAM(),
	   getprotobyname("tcp")) || croak __PACKAGE__, " socket: $!";
    setsockopt($socket, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(),
	       pack("l",1)) || croak __PACKAGE__, " setsockopt: $!";
    my $sockaddr = Socket::pack_sockaddr_in(0, Socket::inet_aton($host));
    bind($socket, $sockaddr) || croak __PACKAGE__, " bind: $!";
    listen($socket, Socket::SOMAXCONN()) || croak __PACKAGE__, " listen: $!";
    $sockaddr = getsockname($socket);
    my ($port,$addr) = Socket::unpack_sockaddr_in($sockaddr);

    my $meta = {
	sockaddr => $sockaddr,
	socket => $socket,
	host => $host,
	host2 => Socket::inet_aton($addr),
	port => $port,

	creator_pid => $$,
	creator_tid => $threads_avail && threads->tid,
	style => $threads_avail ? 'threaded' : 'forked',

	keep_alive => $OPTS{keep_alive},
	idle_timeout => $OPTS{idle_timeout},
	version => $Patro::Archy::VERSION,
    };

    $Patro::SERVER_VERSION = $Patro::Archy::VERSION;

    my $obj = {};
    my @store;

    if ($threads_avail) {
	for (@_) {
	    local $threads::shared::clone_warn = undef;
	    eval { $_ = threads::shared::shared_clone($_) };
	    if ($@ =~ /CODE|GLOB/) {
		require Patro::LeumJelly;
		warn $@;
		$threads::shared::clone_warn = 0;
		$_ = threads::shared::shared_clone($_);
	    }
	}
    }
    foreach my $o (@_) {
	my ($num,$str);
	{
	    no overloading;
	    no warnings 'portable';
	    $str = "$o";
	    ($num) = $str =~ /x(\w+)/;
	    $num = hex($num);
	}
	$obj->{$num} = $o;
	my $reftype = Scalar::Util::reftype($o);
	my $ref = CORE::ref($o);
	if ($ref eq 'threadsx::shared::code') {
	    $ref = $reftype = 'CODE*';
	} elsif ($ref eq 'threadsx::shared::glob') {
	    $ref = $reftype = 'GLOB';
	}
	my $store = {
	    ref => $ref,
	    reftype => $reftype,
	    id => $num
	};
	if (overload::Overloaded($o)) {
	    if ($ref ne 'CODE' && $ref ne 'CODE*' && $ref ne 'GLOB') {
		$store->{overload} = _overloads($o);
	    }
	}
	push @store, $store;
    }
    my $self = bless {
	meta => $meta,
	store => \@store,
	obj => $obj
    }, __PACKAGE__;
    $self->{config} = $self->config;
    $self->start_server;
    eval { push @SERVERS, $self };
    warn $@ if $@;
    if (@SERVERS == 1) {
	eval q~END {
            if ($Patro::Archy::threads_avail) {
                $_->detach for threads->list(threads::running);
	    }
	}~;
    }
    return $self;
}


sub start_server {
    my $self = shift;
    my $meta = $self->{meta};
    if ($meta->{style} eq 'threaded') {
	my $server_thread;
	$server_thread = threads->create(
	    sub {
		$SIG{KILL} = sub { exit };
		$SIG{CHLD} = sub { $self->watch_for_finishers(@_) };
		$SIG{ALRM} = sub { $self->watch_for_finishers(@_) };
		if ($self->{meta}{pid_file}) {
		    open my $fh, '>>', $self->{meta}{pid_file};
		    flock $fh, 2;
		    seek $fh, 0, 2;
		    print {$fh} "$$-", threads->tid, "\n";
		    close $fh;
		}
		$self->accept_clients;
		return;
	    } );
	$self->{meta}{server_thread} = $server_thread;
	$self->{meta}{server_pid} = $$;
	$self->{meta}{server_tid} = $server_thread->tid;
	#$server_thread->detach;
    } else {
	my $pid = CORE::fork();
	if (!defined($pid)) {
	    croak __PACKAGE__, " fork: $!";
	}
	if ($pid == 0) {
	    if ($self->{meta}{pid_file}) {
		open my $fh, '>>', $self->{meta}{pid_file};
		flock $fh, 2;
		seek $fh, 0, 2;
		print {$fh} "$$\n";
		close $fh;
	    }
	    $self->accept_clients;
	    exit;
	}
	$self->{meta}{server_pid} = $pid;
    }
}

# return list of operators that are overloaded on the given object
my @oplist;
sub _overloads {
    my $obj = shift;
    return unless overload::Overloaded($obj);
    if (!@oplist) {
	@oplist = split ' ',join(' ',values %overload::ops);
    }

    my %ops = map { $_ => 1 } grep { overload::Method($obj,$_) } @oplist;

    # we also need to account for the operations that are *implicitly*
    # overloaded.

    # Many ops can be generated out of 0+, "", or bool
    if ($ops{"0+"} || $ops{'""'} || $ops{bool}) {
	$ops{$_}++ for qw(0+ "" bool int ! qr . x .= x= <> -X);
    }

    # assignment ops can be generated from binary ops
    foreach my $binop (qw(. x + - * / ** % & | ^ << >> &. |. ^.)) {
	$ops{$binop . "="}++ if $ops{$binop};
    }

    # all comparison ops can be generated from <=> and cmp
    @ops{qw{< <= > >= == !=}} = (1) x 6 if $ops{"<=>"};
    @ops{qw(le lt ge gt eq ne)} = (1) x 6 if $ops{cmp};

    $ops{neg}++ if $ops{"-"};
    $ops{"--"}++ if $ops{"-="};
    $ops{abs}++ if $ops{"<"} && $ops{neg};
    $ops{"++"}++ if $ops{"+="};

    # all ops are overloaded if there is a 'nomethod' specified
    @ops{@oplist} = (1) x @oplist if $ops{nomethod};
    return [keys %ops];
}

sub config {
    my $self = shift;
    my $config_data = {
	host => $self->{meta}{host},
	port => $self->{meta}{port},
	store => $self->{store},
	style => $self->{meta}{style},
	version => $Patro::Archy::VERSION
    };
    return bless $config_data, 'Patro::Config';
}

########################################

sub Patro::Config::to_string {
    my ($self) = @_;
    return Patro::LeumJelly::serialize({%$self});
}

sub Patro::Config::to_file {
    my ($self,$file) = @_;
    if (!$file) {
	# TODO: select a temp filename
    }
    my $fh;
    if (!open($fh, '>', $file)) {
	croak "Patro::Config::to_file: could not write cfga file '$file': $!";
    }
    print {$fh} $self->to_string;
    close $fh;
    return $file;
}

sub Patro::Config::from_string {
    my ($self, $string) = @_;
    my $cfg = Patro::LeumJelly::deserialize($string);
    return bless $cfg, 'Patro::Config';
}

sub Patro::Config::from_file {
    my ($self, $file) = @_;
    if (!defined($file) && !CORE::ref($self) && $self ne 'Patro::Config') {
	$file = $self;
    }
    my $fh;
    if (CORE::ref($file) eq 'GLOB') {
	$fh = $file;
    } elsif (!open $fh, '<' ,$file) {
	croak "Patro::Config::fron_file: could not read cfg file '$file': $!";
    }
    my $data = <$fh>;
    close $fh;
    return Patro::Config->from_string($data);
}

########################################

sub accept_clients {
    # accept connection from client
    # spin off connection to separate thread or process
    # perform request_response_loop on the client connection
    my $self = shift;
    my $meta = $self->{meta};

    $meta->{last_connection} = time;
    $meta->{finished} = 0;

    while (!$meta->{finished}) {
	$SIG{CHLD} = sub { $self->watch_for_finishers(@_) };
	$SIG{ALRM} = sub { $self->watch_for_finishers(@_) };
	alarm ($OPTS{fincheck_freq} || 5);
	my $client;
	my $server = $meta->{socket};
	my $paddr = accept($client,$server);
	if (!$paddr) {
	    next if $!{EINTR};
	    next if $!{ECHILD} || $!==10;  # !?! why $!{ECHILD} not suff on Lin?
	    ::xdiag("accept failure, %errno is",\%!);
	    croak __PACKAGE__, ": accept ", 0+$!," $!";
	}
	$meta->{last_connection} = time;

	$self->start_subserver($client);
	$self->watch_for_finishers('MAIN');
    }
}

sub start_subserver {
    my ($self,$client) = @_;
    if ($self->{meta}{style} eq 'forked') {
	my $pid = CORE::fork();
	if (!defined($pid)) {
	    croak __PACKAGE__,": fork after accept $!";
	}
	if ($pid != 0) {
	    if ($self->{meta}{pid_file}) {
		open my $fh, '>>', $self->{meta}{pid_file};
		flock $fh, 2;
		seek $fh, 0, 2;
		print {$fh} "$pid\n";
		close $fh;
	    }
	    $self->{meta}{pids}{$pid}++;
	    return;
	}
	$self->request_response_loop($client);
	exit;
    } else {
	my $subthread = threads->create(
	    sub {
		$self->request_response_loop($client);
		threads->self->detach;
		return;
	    } );
	if ($self->{meta}{pid_file}) {
	    open my $fh, '>>', $self->{meta}{pid_file};
	    flock $fh, 2;
	    seek $fh, 0, 2;
	    print {$fh} "$$-", $subthread->tid, "\n";
	    close $fh;
	}
	$self->{meta}{pids}{"$$-" . $subthread->tid}++;
	push @{$self->{meta}{subthreads}}, $subthread;

	# $subthread->detach ?

	return;
    }
}

sub watch_for_finishers {
    my ($self,$sig) = @_;
    alarm 0;

    # XXX - how do you know when a thread is finished?
    # what if it is a detached thread?

    while ((my $pid = waitpid(-1,WNOHANG())) > 0 && WIFEXITED($?)) {
	delete $self->{meta}{pids}{$pid};
    }
    if ($self->{meta}{subthreads}) {
	my $n = @{$self->{meta}{subthreads}};
	my $n1 = threads->list(threads::all());
	my $n2 = threads->list(threads::running());
	my @joinable = threads->list(threads::joinable());
	if (@joinable) {
	    foreach my $subthread  (@joinable) {
		my ($i) = grep {
		    $self->{meta}{subthreads}{$_} == $subthread 
		} 0 .. $n-1;
		if (!defined($i)) {
		    warn "subthread $subthread not found on this server!";
		    next;
		}
		$self->{meta}{subthreads}[$i]->join;
		$self->{meta}{subthreads}[$i] = undef;
	    }
	    $self->{meta}{subthreads} =
		[ grep { defined } @{$self->{meta}{subthreads} } ];
	}
    }
    unless ($self->still_active) {
	$self->{meta}{finished}++;
    }
    $SIG{ALRM} = sub { $self->watch_for_finishers(@_) };
    $SIG{CHLD} = sub { $self->watch_for_finishers(@_) };
    alarm ($OPTS{fincheck_freq} || 5);
}

sub still_active {
    my $self = shift;
    my $meta = $self->{meta};
    if (time <= $meta->{keep_alive}) {
	return 1;
    }
    if (time < $meta->{last_connection} + $meta->{idle_timeout}) {
	return 1;
    }
    if (keys %{$meta->{pids}}) {
	return 1;
    }
    return;
}

sub request_response_loop {
    my ($self, $client) = @_;

    local $Patro::Archy::disconnect = 0;
    my $fh0 = select $client;
    $| = 1;
    select $fh0;

    while (my $req = readline($client)) {
	next unless $req =~ /\S/;
	sxdiag("server: got request '$req'");
	my $resp = $self->process_request($req);
	sxdiag("server: response to request is ",$resp);
	$resp = $self->serialize_response($resp);
	sxdiag("server: serialized response to request is ",$resp);
	print {$client} $resp,"\n";
	last if $Patro::Archy::disconnect;
    }
    close $client;
    return;
}

our $SIDES;    # for the server to activate or suppress some
               # side-effects from the lower levels of the
               # request handler

sub process_request {
    my ($self,$request) = @_;
    croak "process_request: expected scalar request" if ref($request);

    $request = Patro::LeumJelly::deserialize($request);
    my $topic = $request->{topic};
    if (!defined($topic)) {
	return $self->error_response("bad topic in request '$_[1]'");
    }
    
    my $has_args = $request->{has_args};
    my $args = $request->{args};
    if ($request->{has_args}) {
	local $@;
	$args = [ map {
	    if (CORE::ref($_) eq '.Patroon') {
		eval { $self->{obj}{$$_} };
	    } else {
		$_
	    } } @{$request->{args}} ];
	if ($@) {
	    return $self->error_response($@);
	}
    }
    my $id = $request->{id};
    my $cmd = $request->{command};
    my $ctx = $request->{context};
    my @orig_args = $has_args ? @$args : ();
    my @orig_refs = $has_args ? \ (@$args) : ();
    my @orig_dump = map Patro::LeumJelly::serialize([$_]), @$args;
    local $! = 0;
    local $? = 0;
    local $SIDES = {};
    my @r;
    our $DEBUG;
    local $DEBUG = $DEBUG || $request->{_debug} || 0;

    if ($topic eq 'META') {
	@r = $self->process_request_META($id,$cmd,$ctx,$has_args,$args);
    } elsif ($topic eq 'HASH') {
	@r = $self->process_request_HASH($id,$cmd,$ctx,$has_args,$args);
    } elsif ($topic eq 'ARRAY') {
	@r = $self->process_request_ARRAY($id,$cmd,$ctx,$has_args,$args);
    } elsif ($topic eq 'SCALAR') {
	@r = $self->process_request_SCALAR($id,$cmd,$ctx,$has_args,$args);
    } elsif ($topic eq 'METHOD') {
	@r = $self->process_request_METHOD($id,$cmd,$ctx,$has_args,$args);
    } elsif ($topic eq 'CODE') {
	@r = $self->process_request_CODE($id,undef,$ctx,$has_args,$args);
    } elsif ($topic eq 'HANDLE') {
	@r = $self->process_request_HANDLE($id,$cmd,$ctx,$has_args,$args);
    } elsif ($topic eq 'OVERLOAD') {
	my $obj = $self->{obj}{$id};
	@r = $self->process_request_OVERLOAD($obj,$cmd,$args,$ctx);
    } elsif ($topic eq 'REF') {
	@r = $self->process_request_REF($id,$cmd,$ctx,$has_args,$args);
    } else {
	@r = ();
	$@ = __PACKAGE__ . ": unrecognized topic '$topic' in proxy request";
    }
    if (@r && CORE::ref($r[0]) eq '.Patroclus') {
	return $r[0];
    }
    my $sides = bless {}, '.Patroclus';

    $sides->{errno} = 0 + $! if $!;
    $sides->{errno_extended} = $^E if $^E;
    $sides->{child_error} = $? if $?;
    $sides->{error} = $@ if $@;

    # how to update elements of @_ that have changes?
    # three implementations below. Pick one.
    #   1. "side A" - return all elements of @_. You will have to
    #      filter out "Modification of a read-only element attempted ..."
    #      messages
    #   2. "side B" - do a deep comparison of original and final
    #      elements of @_, return the ones that mismatch I CHOOSE YOU!
    #   3. original implementation - do shallow comparison of original
    #      and final elements of @_. Insufficient for code that updates
    #      nested data of the inputs
    my (@out,@outref);

    # "sideB" - do a deep compare for all arguments
    for (my $j=0; $j<@$args && !$SIDES->{no_out}; $j++) {
	my $dj = Patro::LeumJelly::serialize([$args->[$j]]);
	for (my $i=0; $i<@orig_refs; $i++) {
	    next if $orig_refs[$i] != \$args->[$j];
	    if ($orig_dump[$i] ne $dj) {
		push @out, $i, $args->[$j];
	    }
	}
    }
    $sides->{sideB} = 1;

    $sides->{out} = \@out if @out;
    $sides->{outref} = \@outref if @outref;
    if ($ctx >= 2) {
	return $self->list_response($sides, @r);
    } elsif ($ctx == 1 && defined $r[0]) {
	my $y = $self->scalar_response($sides, $r[0]);
#	if ($topic eq 'REF') { ::xdiag("response:",$y) }
	return $y;
    } else {
	return $self->void_response($sides);
    }
}

sub process_request_META {
    my ($self,$id,$cmd,$ctx,$has_args,$args) = @_;
    if ($cmd eq 'disconnect') {
	$Patro::Archy::disconnect = 1;
	return bless { disconnect_ok => 1 }, '.Patroclus';
    }
    my $obj = $self->{obj}{$id};
    if ($cmd eq 'ref') {
	return CORE::ref($obj);
    } elsif ($cmd eq 'reftype') {
	return Scalar::Util::reftype($obj);
    } elsif ($cmd eq 'destroy') {
	delete $self->{obj}{$id};
	my @ids = keys %{$self->{obj}};
	if (@ids == 0) {
	    $Patro::Archy::disconnect = 1;
	    return bless { disconnect_ok => 1 }, '.Patroclus';
	} else {
	    return bless { disconnect_ok => 0,
		     num_reminaing_objs => 0+@ids }, '.Patroclus';
	}
    } else {
	$@ = "Patro: unsupported meta command '$cmd'";
	return;
    }
}

sub process_request_HASH {
    my ($self,$id,$cmd,$ctx,$has_args,$args) = @_;
    my $obj = $self->{obj}{$id};
    if (reftype($obj) ne 'HASH') {
	$@ = "Not a HASH reference";
	return;
	# !!! what if '%{}' op is overloaded?
    }
    if ($cmd eq 'STORE') {
	my ($key,$val) = @$args;
	my $old_val = $obj->{$key};
	$obj->{$key} = threads::shared::shared_clone($val);
	return $old_val;
    } elsif ($cmd eq 'FETCH') {
	return $obj->{$args->[0]};
    } elsif ($cmd eq 'DELETE') {
	return delete $obj->{$args->[0]};
    } elsif ($cmd eq 'EXISTS') {
	return exists $obj->{$args->[0]};
    } elsif ($cmd eq 'CLEAR') {
	%$obj = ();
	return;
    } elsif ($cmd eq 'FIRSTKEY') {
	keys %$obj;
	my ($k,$v) = each %$obj;
	return $k;
    } elsif ($cmd eq 'NEXTKEY') {
	my ($k,$v) = each %$obj;
	return $k;
    } elsif ($cmd eq 'SCALAR') {
	return scalar %$obj;
    } else {
	$@ = "HASH function '$cmd' not recognized";
	return;
    }
}

sub process_request_ARRAY {
    my ($self,$id,$cmd,$ctx,$has_args,$args) = @_;
    my $obj = $self->{obj}{$id};
    if (reftype($obj) ne 'ARRAY') {
	$@ = "Not an ARRAY ref";
	return;
    }
    if ($cmd eq 'STORE') {
	my ($index,$val) = @$args;
	my $old_val = $obj->[$index];
	# ?!!!? does $val have to be shared?
	eval { $obj->[$index] = threads::shared::shared_clone($val) };
	return $old_val;
    } elsif ($cmd eq 'FETCH') {
	return eval { $obj->[$args->[0]] };
    } elsif ($cmd eq 'FETCHSIZE') {
	return scalar @$obj;
    } elsif ($cmd eq 'STORESIZE' || $cmd eq 'EXTEND') {
	my $n = $#{$obj} = $args->[0]-1;
	return $n+1;
    } elsif ($cmd eq 'SPLICE') {
	my ($off,$len,@list) = @$args;
	if ($off < 0) {
	    $off += @$obj;
	    if ($off < 0) {
		$@ = "Modification of non-createable array value attempted, "
		    . "subscript $off";
		return;
	    }
	}
	if (!defined($len) || $len eq 'undef') {
	    $len = @{$obj} - $off;
	}
	if ($len < 0) {
	    $len += @{$obj} - $off;
	    if ($len < 0) {
		$len = 0;
	    }
	}
	my @val = splice @{$obj}, $off, $len, @list;
	$SIDES->{no_out} = 1; # don't try to update @_
	# SPLICE is the only ARRAY function that doesn't assume scalar context
	if ($ctx == 1) {
	    return @val > 0 ? $val[-1] : undef;
	} else {
	    return @val;
	}
    } elsif ($cmd eq 'PUSH') {
	return push @{$obj}, map threads::shared::shared_clone($_), @$args;
    } elsif ($cmd eq 'UNSHIFT') {
	return unshift @{$obj}, map threads::shared::shared_clone($_), @$args;
    } elsif ($cmd eq 'POP') {
	return pop @{$obj};
    } elsif ($cmd eq 'SHIFT') {
	return shift @{$obj};
    } elsif ($cmd eq 'EXISTS') {
	return exists $obj->[$args->[0]];
    } else {
	$@ = "tied ARRAY function '$cmd' not recognized";
	return;
    }
}

sub process_request_SCALAR {
    my ($self,$id,$cmd,$ctx,$has_args,$args) = @_;
    my $obj = $self->{obj}{$id};
    if (reftype($obj) ne 'SCALAR') {
	$@ = "Not a SCALAR reference";
	return;
    }
    if ($cmd eq 'STORE') {
	my $val = ${$obj};
	${$obj} = threads::shared::shared_clone($args->[0]);
	return $val;	
    } elsif ($cmd eq 'FETCH') {
	return ${$obj};
    } else {
	$@ = "tied SCALAR function '$cmd' not recognized";
	return;
    }
}

sub process_request_METHOD {
    my ($self,$id,$command,$context,$has_args,$args) = @_;
    my $obj = $self->{obj}{$id};
    if (!$obj) {
	$@ = "Bad object id '$id' in proxy method call";
	return;
    }
    my @r;
    if ($command =~ /::/) {
	no strict 'refs';
	if ($context < 2) {
	    @r = scalar eval { $has_args ? &$command($obj,@$args)
				   : &$command($obj) };
	} else {
	    @r = eval { $has_args ? &$command($obj,@$args)
			          : &$command($obj) };
	}
    } elsif ($context < 2) {
	@r = scalar eval { $has_args ? $obj->$command(@$args)
			             : $obj->$command };
    } else {
	@r = eval { $has_args ? $obj->$command(@$args)
			      : $obj->$command };
    }
    return @r;
}

sub process_request_HANDLE {
    my ($self,$id,$command,$context,$has_args,$args) = @_;
    my $obj = $self->{obj}{$id};
    my $fh = CORE::ref($obj) eq 'threadsx::shared::glob' ? $obj->glob : $obj;
    if ($command eq 'PRINT') {
	my $z = print {$fh} @$args;
	return $z;
    } elsif ($command eq 'PRINTF') {
	if ($has_args) {
	    my $template = shift @$args;
	    my $z = printf {$fh} $template, @$args;
	    return $z;
	} else {
	    # I don't think we can get here through the proxy
	    my $z = printf {$fh} "";
	    return $z;
	}
    } elsif ($command eq 'WRITE') {
	if (@$args < 2) {
	    return $self->error_response("Not enough arguments for syswrite");
	}
	return syswrite($fh, $args->[0],
	                     $args->[1] // undef, $args->[2] // undef);
    } elsif ($command eq 'READLINE') {
	my @val;
	if ($context > 1) {
	    my @val = readline($fh);
	    return @val;
	} else {
	    my $val = readline($fh);
	    return $val;
	}
    } elsif ($command eq 'GETC') {
	my $ch = getc($fh);
	return $ch;
    } elsif ($command eq 'READ' || $command eq 'READ?' ||
	     $command eq 'SYSREAD') {
	local $Patro::read_sysread_flag;  # don't clobber
	if (@$args < 2) {
	    # I don't think we can get here through the proxy
	    $@ = "Not enough arguments for " . lc($command);
	    return;
	}
	my (undef, $len, $off) = @$args;
	my $z;
	if ($command eq 'SYSREAD' ||
	    ($command eq 'READ?' && fileno($fh) >= 0)) {
	    $z = sysread $fh, $args->[0], $len, $off || 0;
	} else {
	    # sysread doesn't work, for example, on file handles opened
	    # from a reference to a scalar
	    $z = read $fh, $args->[0], $len, $off || 0;
	}
	return $z;
    } elsif ($command eq 'EOF') {
	return eof($fh);
    } elsif ($command eq 'FILENO') {
	my $z = fileno($fh);
	return $z;
    } elsif ($command eq 'SEEK') {
	if (@$args < 2) {
	    $@ = "Not enough arguments for seek";
	    return;
	} elsif (@$args > 2) {
	    $@ = "Too many arguments for seek";
	    return;
	} else {
	    my $z = seek $fh, $args->[0], $args->[1];
	    return $z;
	}
    } elsif ($command eq 'TELL') {
	my $z = tell($fh);
	return $z;
    } elsif ($command eq 'BINMODE') {
	my $z;
	if (@$args) {
	    $z = binmode $fh, $args->[0];
	} else {
	    $z = binmode $fh;
	}
	return $z;
    } elsif ($command eq 'CLOSE') {
	if ($Patro::SECURE) {
	    $@ = "Patro: insecure CLOSE operation on proxy filehandle";
	    return;
	}
	my $z = close $fh;
	return $z;    
    } elsif ($command eq 'OPEN') {
	if ($Patro::SECURE) {
	    $@ = "Patro: insecure OPEN operation on proxy filehandle";
	    return;
	}
	my $z;
	my $mode = shift @$args;
	if (@$args == 0) {
	    $z = open $fh, $mode;
	} else {
	    my $expr = shift @$args;
	    if (@$args == 0) {
		$z = open $fh, $mode, $expr;
	    } else {
		$z = open $fh, $mode, $expr, @$args;
	    }
	}

	# it is hard to set autoflush from the proxy.
	# Since it is usually what you want, let's do it here.
	if ($z) {
	    my $fh_sel = select $fh;
	    $| = 1;
	    select $fh_sel;
	}
	return $z;
    }
    # commands that are not in the tied filehandle 
    elsif ($command eq 'TRUNCATE') {
	my $z = truncate $fh, $args->[0];
	return $z;
    } elsif ($command eq 'FCNTL') {
	my $z = fcntl $fh, $args->[0], $args->[1];
	return $z;
    } elsif ($command eq 'FLOCK') {
	my $z = flock $fh, $args->[0];
	return $z;
    } elsif ($command eq 'STAT') {
	if ($context < 2) {
	    return scalar stat $fh;
	} else {
	    return stat $fh;
	}
    } elsif ($command eq 'LSTAT') {
	if ($context < 2) {
	    return scalar lstat $fh;
	} else {
	    return lstat $fh;
	}
    } elsif ($command eq '-X') {
	my $key = $args->[0];
	return eval "-$key \$fh";
    } elsif ($command eq 'SYSOPEN') {
	if ($Patro::SECURE) {
	    $@ = "Patro: insecure SYSOPEN operation on proxy filehandle";
	    return;
	}
        my $z = @$args <= 2 ? sysopen $fh, $args->[0], $args->[1]
                      : sysopen $fh, $args->[0], $args->[1], $args->[2];
        return $z;

    # commands that operate on DIRHANDLEs
    } elsif ($command eq 'OPENDIR') {
        if ($Patro::SECURE) {
            $@ = "Patro: insecure OPENDIR operation on proxy dirhandle";
            return;
        }
        return opendir $fh, $args->[0];
    } elsif ($command eq 'REWINDDIR') {
        return rewinddir $fh;
    } elsif ($command eq 'TELLDIR') {
        return telldir $fh;
    } elsif ($command eq 'READDIR') {
        if ($context < 2) {
            return scalar readdir $fh;
        } else {
            my @r = readdir $fh;
            return @r;
        }
    } elsif ($command eq 'SEEKDIR') {
        return seekdir $fh, $args->[0];
    } elsif ($command eq 'CLOSEDIR') {
        return closedir $fh;
    } elsif ($command eq 'CHDIR') {
        return chdir $fh;
	
    } else {
	$@ = "tied HANDLE function '$command' not found";
	return;
    }
}

sub process_request_CODE {
    my ($self,$id,$command_NOTUSED,$context,$has_args,$args) = @_;
    my $sub = $self->{obj}{$id};
    if (CORE::ref($sub) eq 'threadsx::shared::code') {
	$sub = $sub->code;
    }
    if ($context < 2) {
	return scalar eval { $has_args ? $sub->(@$args) : $sub->() };
    } else {
	return eval { $has_args ? $sub->(@$args) : $sub->() };
    }
}

sub process_request_OVERLOAD {
    my ($self,$x,$op,$args,$context) = @_;
    if ($op eq '@{}') {
	my $z = eval { \@$x };
	$@ &&= "Not an ARRAY reference";
	return $z;
    } elsif ($op eq '%{}') {
	my $z = eval { \%$x };
	$@ &&= "Not a HASH reference";
	return $z;
    } elsif ($op eq '&{}') {
	my $z = eval { \&$x };
	$@ &&= "Not a CODE reference";
	return $z;
    } elsif ($op eq '${}') {
	my $z = eval { \$$x };
	$@ &&= "Not a SCALAR reference";
	return $z;
    } # elsif ($op eq '*{}') { return \*$x; }
    my ($y,$swap) = @$args;
    if ($swap) {
	($x,$y) = ($y,$x);
    }
    local $@ = '';
    my $z;
    if ($op =~ /[&|~^][.]=?/) {
        $op =~ s/\.//;
    }
    if ($op eq '-X') {
        $z = eval "-$y \$x";
    } elsif ($op eq 'neg') {
        $z = eval { -$x };
    } elsif ($op eq '!' || $op eq '~' || $op eq '++' || $op eq '--') {
        $z = eval "$op\$x";
    } elsif ($op eq 'qr') {
        $z = eval { qr/$x/ };
    } elsif ($op eq 'atan2') {
        $z = eval { atan2($x,$y) };
    } elsif ($op eq 'cos' || $op eq 'sin' || $op eq 'exp' || $op eq 'abs' ||
             $op eq 'int' || $op eq 'sqrt' || $op eq 'log') {
        $z = eval "$op(\$x)";
    } elsif ($op eq 'bool') {
        $z = eval { $x ? 1 : 0 };  # this isn't right
    } elsif ($op eq '0+') {
        $z = eval "0 + \$x"; # this isn't right, either
    } elsif ($op eq '""') {
        $z = eval { "$x" };
    } elsif ($op eq '<>') {
        # always scalar context readline
        $z = eval { readline($x) };
    } else {  # binary operator
        $z = eval "\$x $op \$y";
    }
    if ($@) {
	return;
    }
    if ($threads_avail) {
	$z = threads::shared::shared_clone($z);
    }
    return $z;
}

sub process_request_REF {
    my ($self,$id,$command,$context,$has_args,$args) = @_;
    my $obj = $self->{obj}{$id};
    if (reftype($obj) ne 'REF') {
	$@ = "Not a REF";
	return;
    }
    if ($command eq 'deref') {
	return $$obj;
    }
    $@ = "$command is not an appropriate operation for REF";
    return;
}

########################################

sub void_response {
    my $addl = {};
    if (@_ > 0 && CORE::ref($_[-1]) eq '.Patroclus') {
	$addl = pop @_;
    }
    return +{ context => 0, response => undef, %$addl };
}

sub scalar_response {
    my ($self,$sides,$val) = @_;
    return +{
	context => 1,
	response => $val,
	%$sides
    };
}

sub list_response {
    my ($self,$sides,@val) = @_;
    return +{
	context => 2,
	response => \@val,
	%$sides
    };
}

sub error_response {
    my ($self,@msg) = @_;
    return { error => join('', @msg) };
}

########################################

sub serialize_response {
    my ($self, $resp) = @_;
    if ($resp->{context}) {
	if ($resp->{context} == 1) {
	    $resp->{response} = patrol($self,$resp,$resp->{response});
	} elsif ($resp->{context} == 2) {
	    $resp->{response} = [
		map patrol($self,$resp,$_), @{$resp->{response}} ];
	}
    }

    if ($resp->{out}) {
	$resp->{out} = [ map patrol($self,$resp,$_), @{$resp->{out}} ];
    }

    sxdiag("Patro::Archy: final response before serialization: ",$resp);
    $resp = Patro::LeumJelly::serialize($resp);
    return $resp;
}

# we should not send any serialized references back to the client.
# replace any references in the response with an
# object id.
sub patrol {
    my ($self,$resp,$obj) = @_;
    sxdiag("patrol: called on: ",defined($obj) ? "$obj" : "<undef>");
    return $obj unless ref($obj);

    if ($threads_avail) {
	if (CORE::ref($obj) eq 'CODE') {
	    $obj = threadsx::shared::code->new($obj);
	    sxdiag("patrol: coderef converted");
	} elsif (CORE::ref($obj) eq 'GLOB') {
	    $obj = threadsx::shared::glob->new($obj);
	    sxdiag("patrol: glob converted");
	}
    }

    my $id = do {
	no overloading;
	0 + $obj;
    };

    if (!$self->{obj}{$id}) {
	$self->{obj}{$id} = $obj;
	my $ref = CORE::ref($obj);
	my $reftype;
	if ($ref eq 'threadsx::shared::code') {
	    $ref = 'CODE';
	    $reftype = 'CODE';
	} elsif ($ref eq 'threadsx::shared::glob') {
	    $ref = 'GLOB';
	    $reftype = 'GLOB';
	} else {
	    $reftype = Scalar::Util::reftype($obj);
	}
	sxdiag("patrol: ref types for $id are $ref,$reftype");
	$resp->{meta}{$id} = {
	    id => $id, ref => $ref, reftype => $reftype
	};
	if (overload::Overloaded($obj)) {
	    $resp->{meta}{$id}{overload} = _overloads($obj);
	}
	sxdiag("new response meta: ",$resp->{meta}{$id});
    } else {
	sxdiag("id $id has been seen before");
    }
    return bless \$id,'.Patrobras';
}

sub TEST_MODE {
    if ($INC{'perl5db.pl'}) {
	::xdiag("TEST_MODE adjusted for debugging");
	$OPTS{keep_alive} = 3600;
	$OPTS{fincheck_freq} = 3500;
	$OPTS{idle_timeout} = 3600;
	alarm 9999;
	return;
    }
    $OPTS{keep_alive} = 2;
    $OPTS{fincheck_freq} = 2;
    $OPTS{idle_timeout} = 1;
    if ($threads_avail) {
	$OPTS{fincheck_freq} = "0 but true";	    
    }
}

1;

=head1 NAME

Patro::Archy - remote object server for Patro

=head1 VERSION

0.15

=head1 DESCRIPTION

A server class for making references available to proxy clients
in the L<Patro> distribution.
The server handles requests for any references that are being served,
manipulates references on the server, and returns the results of
operations to the proxy objects on the clients.

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2017, Marty O'Brien

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
