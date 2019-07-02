package RPC::Switch::Client;
use Mojo::Base 'Mojo::EventEmitter';

our $VERSION = '0.15'; # VERSION

#
# Mojo's default reactor uses EV, and EV does not play nice with signals
# without some handholding. We either can try to detect EV and do the
# handholding, or try to prevent Mojo using EV.
#
BEGIN {
	$ENV{'MOJO_REACTOR'} = 'Mojo::Reactor::Poll' unless $ENV{'MOJO_REACTOR'};
}

use feature 'state';

# more Mojolicious
use Mojo::IOLoop;
use Mojo::IOLoop::Stream;
use Mojo::Log;

# standard perl
use Carp qw(croak);
use Scalar::Util qw(blessed refaddr);
use Cwd qw(realpath);
use Data::Dumper;
use Encode qw(encode_utf8 decode_utf8);
use File::Basename;
use IO::Handle;
use POSIX ();
use Scalar::Util qw(blessed refaddr);
use Storable;
use Sys::Hostname;

# from cpan
use JSON::RPC2::TwoWay 0.04; # for access to the request
# JSON::RPC2::TwoWay depends on JSON::MaybeXS anyways, so it can be used here
# without adding another dependency
use JSON::MaybeXS;
use MojoX::NetstringStream 0.06;


has [qw(
	actions address auth cb_used channels clientid conn debug ioloop
	json lastping log method ns ping_timeout port rpc timeout tls token
	who
)];

# keep in sync with the rpc-switch
use constant {
	RES_OK                 => 'RES_OK',
	RES_WAIT               => 'RES_WAIT',
	RES_TIMEOUT            => 'RES_TIMEOUT',
	RES_ERROR              => 'RES_ERROR',
	RES_OTHER              => 'RES_OTHER', # 'dunno'
	WORK_OK                => 0,           # exit codes for work method
	WORK_PING_TIMEOUT      => 92,
	WORK_CONNECTION_CLOSED => 91,
};

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new();

	my $debug = $args{debug} // 0; # or 1?

	$self->{address} = $args{address} // '127.0.0.1';
	$self->{cb_used} = {}; # avoid calling cb twice in a timeout scenario
	$self->{channels} = {}; # per channel hash of waitids
	$self->{debug} = $debug;
	$self->{json} = $args{json} // 1;
	$self->{ping_timeout} = $args{ping_timeout} // 300;
	$self->{ioloop} = $args{ioloop} // Mojo::IOLoop->singleton;
	$self->{log} = $args{log}
		// Mojo::Log->new(level => ($debug) ? 'debug' : 'info');
	$self->{method} = $args{method} // 'password';
	$self->{port} = $args{port} // 6551;
	$self->{timeout} = $args{timeout} // 60;
	$self->{tls} = $args{tls} // 0;
	$self->{tls_ca} = $args{tls_ca};
	$self->{tls_cert} = $args{tls_cert};
	$self->{tls_key} = $args{tls_key};
	$self->{token} = $args{token} or croak 'no token?';
	$self->{who} = $args{who} or croak 'no who?';
	$self->{autoconnect} = $args{autoconnect} // 1;

	return $self unless $self->{autoconnect};

	$self->connect;

	return $self if $self->{auth};
	return;
}

sub connect {
	my $self = shift;

	delete $self->{_exit};
	delete $self->{auth};
	$self->{actions} = {};

	$self->on(disconnect => sub {
		my ($self, $code) = @_;
		$self->{_exit} = $code;
		$self->ioloop->stop;
	});

	my $rpc = JSON::RPC2::TwoWay->new(debug => $self->{debug}) or croak 'no rpc?';
	$rpc->register('rpcswitch.greetings', sub { $self->rpc_greetings(@_) }, notification => 1);
	$rpc->register('rpcswitch.ping', sub { $self->rpc_ping(@_) });
	$rpc->register('rpcswitch.channel_gone', sub { $self->rpc_channel_gone(@_) }, notification => 1);
	$rpc->register(
		'rpcswitch.result',
		sub { $self->rpc_result(@_) },
		by_name => 0,
		notification => 1,
		raw => 1
	);

	my $clarg = {
		address => $self->{address},
		port => $self->{port},
		tls => $self->{tls},
	};
	$clarg->{tls_ca} = $self->{tls_ca} if $self->{tls_ca};
	$clarg->{tls_cert} = $self->{tls_cert} if $self->{tls_cert};
	$clarg->{tls_key} = $self->{tls_key} if $self->{tls_key};

	my $clientid = $self->ioloop->client(
		$clarg => sub {
		my ($loop, $err, $stream) = @_;
		if ($err) {
			$err =~ s/\n$//s;
			$self->log->info('connection to API failed: ' . $err);
			$self->{auth} = 0;
			return;
		}
		my $ns = MojoX::NetstringStream->new(stream => $stream);
		$self->{ns} = $ns;
		my $conn = $rpc->newconnection(
			owner => $self,
			write => sub { $ns->write(@_) },
		);
		$self->{conn} = $conn;
		$ns->on(chunk => sub {
			my ($ns2, $chunk) = @_;
			#say 'got chunk: ', $chunk;
			my @err = $conn->handle($chunk);
			$self->log->info('chunk handler: ' . join(' ', grep defined, @err)) if @err;
			$ns->close if $err[0];
		});
		$ns->on(close => sub {
			# this cb is called during global destruction, at
			# least on old perls where
			# Mojo::Util::_global_destruction() won't work
			return unless $conn;
			$conn->close;
			$self->log->info('connection to rpcswitch closed');
			$self->emit(disconnect => WORK_CONNECTION_CLOSED); # todo: doc
		});
	});

	$self->{rpc} = $rpc;
	$self->{clientid} = $clientid;

	# handle timeout?
	my $tmr = $self->ioloop->timer($self->{timeout} => sub {
		my $loop = shift;
		$self->log->error('timeout wating for greeting');
		$loop->remove($clientid); # disconnect
		$self->{auth} = 0;
	});

	$self->log->debug('starting handshake');
	
	# fixme: catch signals?
	$self->_loop(sub { not defined $self->{auth} });

	$self->log->debug('done with handhake?');

	$self->ioloop->remove($tmr);
	$self->unsubscribe('disconnect');

	return $self->{auth};
}

sub is_connected {
	my $self = shift;
	return $self->{auth} && !$self->{_exit};
}

sub rpc_greetings {
	my ($self, $c, $i) = @_;
	$self->ioloop->delay(
		sub {
			my $d = shift;
			die "wrong api version $i->{version} (expected 1.0)" unless $i->{version} eq '1.0';
			$self->log->info('got greeting from ' . $i->{who});
			$c->call('rpcswitch.hello', {who => $self->who, method => $self->method, token => $self->token}, $d->begin(0));
		},
		sub {
			my ($d, $e, $r) = @_;
			my $w;
			#say 'hello returned: ', Dumper(\@_);
			die "hello returned error $e->{message} ($e->{code})" if $e;
			die 'no results from hello?' unless $r;
			($r, $w) = @$r;
			if ($r) {
				$self->log->info("hello returned: $r, $w");
				$self->{auth} = 1;
			} else {
				$self->log->error('hello failed: ' . ($w // ''));
				$self->{auth} = 0; # defined but false
			}
		}
	)->catch(sub {
		my ($err) = @_;
		$self->log->error('something went wrong in handshake: ' . $err);
		$self->{auth} = '';
	});
}

sub call {
	my ($self, %args) = @_;
	my ($done, $status, $outargs);
	$args{waitcb} = sub {
		($status, $outargs) = @_;
		unless ($status and $status eq RES_WAIT) {
			$self->log->error('unexpected status: ' . ($status // 'undef'));
			$done++;
			return;
		}
		$self->log->debug("gotta wait for $outargs");
	};
	$args{resultcb} = sub {
		($status, $outargs) = @_;
		$done++;
	};
	$self->call_nb(%args);

	$self->_loop(sub { !$done });

	return $status, $outargs;
}

sub call_nb {
	my ($self, %args) = @_;
	my $method = $args{method} or die 'no method?';
	my $vtag = $args{vtag};
	my $inargs = $args{inargs} // '{}';
	my $waitcb = $args{waitcb}; # optional
	my $rescb = $args{resultcb} // die 'no result callback?';
	my $timeout = $args{timeout} // 0; # accommodate existing code where this didn't work
	my $reqauth = $args{reqauth};
	my $inargsj;

	if ($self->{json}) {
		$inargsj = $inargs;
		$inargs = decode_json($inargs);
		croak 'inargs is not a json object' unless ref $inargs eq 'HASH';
	} else {
		croak 'inargs should be a hashref' unless ref $inargs eq 'HASH';
		# test encoding
		$inargsj = encode_json($inargs);
		if ($reqauth) {
		}
	}

	if ($reqauth) {
		if (blessed($reqauth)) {
			if ($reqauth->can('_to_reqauth')) {
				# duck typing in action
				$reqauth = $reqauth->_to_reqauth();
			} else {
				croak "Don't know how to convert $reqauth to reqauth hash";
			}
		}
		croak 'reqauth should be a hashref' unless ref $reqauth eq 'HASH';
	}

	if ($timeout > 0) {
		$self->ioloop->timer($timeout => sub {
			$rescb->(RES_TIMEOUT, "timed out after $timeout seconds");
			$self->{cb_used}->{refaddr($rescb)} = 1
				if defined $self->{cb_used}->{refaddr($rescb)};
				# waiting for result notification after RES_WAIT
			$rescb = undef;
		});
	}

	$inargsj = decode_utf8($inargsj);
	$self->log->debug("calling $method with '" . $inargsj . "'" . (($vtag) ? " (vtag $vtag)" : ''));

	my $delay = $self->ioloop->delay( #->steps(
		sub {
			my $d = shift;
			$self->conn->callraw({
				method => $method,
				params => $inargs,
				($reqauth ? (rpcswitch => { vcookie => 'eatme', reqauth => $reqauth }) : ()),
			}, $d->begin(0));
		},
		sub {
			#print Dumper(@_);
			my ($d, $e, $r) = @_;
			if ($e) {
				$e = $e->{error};
				$self->log->error("call returned error: $e->{message} ($e->{code})");
				$rescb->(RES_ERROR, "$e->{message} ($e->{code})") if $rescb;
				return;
			}
			return unless $rescb; # $rescb is undef if a timeout happeded
			my ($status, $outargs) = @{$r->{result}};
			if ($status eq RES_WAIT) {
				#print '@$r', Dumper($r);
				my $vci = $r->{rpcswitch}->{vci};
				unless ($vci) {
					$self->log->error("missing rpcswitch vci after RES_WAIT");
					return;
				}

				# note the relation to the channel so we can throw an error if
				# the channel disappears
				# outargs should contain waitid
				# autovivification ftw?
				$self->{channels}->{$vci}->{$outargs} = $rescb;
				$self->{cb_used}->{refaddr($rescb)} = 0;
				$waitcb->($status, $outargs) if $waitcb;
			} else {
				$outargs = encode_json($outargs) if $self->{json} and ref $outargs;
				$rescb->($status, $outargs);
			}
		}
	)->catch(sub {
		my ($err) = @_;
		$self->log->error("Something went wrong in call_nb: $err");
		$rescb->(RES_ERROR, $err);
		return @_;
	});
}

sub get_status {
	my ($self, $wait_id, $notify) = @_;
  
	my ($ns, $id) = split /:/, $wait_id, 2;
  
	die "no namespace in waitid?" unless $ns;
  
	my $inargs = {
		wait_id => $wait_id,
		notify => ($notify ? JSON->true : JSON->false),
	};
	# meh:
	$inargs = encode_json($inargs) if $self->{json};

	# fixme: reuse call?
	my ($done, $status, $outargs);
	my %args = (
		method => "$ns._get_status",
		inargs => $inargs,
		waitcb => sub {
			($status, $outargs) = @_;
			die "unexpected status" unless $status and $status eq RES_WAIT;
			$done++ unless $notify;
		},
		resultcb => sub {
			($status, $outargs) = @_;
			$done++;
		},
	);
	$self->call_nb(%args);

	$self->_loop(sub { !$done });

	return $status, $outargs;
}

sub rpc_result {
	my ($self, $c, $r) = @_;
	#$self->log->debug('got result: ' . Dumper($r));
	my ($status, $id, $outargs) = @{$r->{params}};
	return unless $id;
	my $vci = $r->{rpcswitch}->{vci};
	return unless $vci;
	my $rescb = delete $self->{channels}->{$vci}->{$id};
	return unless $rescb;
	return if delete $self->{cb_used}->{refaddr($rescb)}; # cb already called
	$outargs = encode_json($outargs) if $self->{json} and ref $outargs;
	$rescb->($status, $outargs);
	return;
}

sub rpc_channel_gone {
	my ($self, $c, $a) = @_;
	my $ch = $a->{channel};
	$self->log->debug("got channel_gone: $ch");
	return unless $ch;
	my $wl = delete $self->{channels}->{$ch};
	return unless $wl;
	for my $rescb (values %$wl) {
		$rescb->(RES_ERROR, 'channel gone');
	}
	return;
}

sub ping {
	my ($self, $timeout) = @_;

	$timeout //= $self->timeout;
	my ($done, $ret);

	$self->ioloop->timer($timeout => sub {
		$done++;
	});

	$self->conn->call('rpcswitch.ping', {}, sub {
		my ($e, $r) = @_;
		if (not $e and $r and $r =~ /pong/) {
			$ret = 1;
		} else {
			%$self = ();
		}
		$done++;
	});

	# we could recurse here
	$self->_loop(sub { !$done });

	return $ret;
}

sub work {
	my ($self) = @_;

	my $pt = $self->ping_timeout;
	my $tmr;
	$tmr = $self->ioloop->recurring($pt => sub {
		my $ioloop = shift;
		$self->log->debug('in ping_timeout timer: lastping: '
			 . ($self->lastping // 0) . ' limit: ' . (time - $pt) );
		return if ($self->lastping // 0) > time - $pt;
		$self->log->error('ping timeout');
		$ioloop->remove($self->clientid);
		$self->{_exit} = WORK_PING_TIMEOUT; # todo: doc
		$ioloop->stop;
		$ioloop->remove($tmr);
	}) if $pt > 0;
	$self->on(disconnect => sub {
		my ($self, $code) = @_;
		$self->{_exit} = $code;
		$self->ioloop->stop;
	});
	$self->{_exit} = WORK_OK;
	$self->log->debug(blessed($self) . ' starting work');
	$self->ioloop->start unless $self->ioloop->is_running;
	$self->log->debug(blessed($self) . ' done?');
	$self->ioloop->remove($tmr) if $tmr;

	return $self->{_exit};
}

sub stop {
	my ($self, $exit) = @_;
	$self->{_exit} = $exit;
	$self->ioloop->stop;
}

sub announce {
	my ($self, %args) = @_;
	my $method = $args{method} or croak 'no method?';
	my $cb = $args{cb} or croak 'no cb?';
	#my $async = $args{async} // 0;
	my $mode = $args{mode} // (($args{async}) ? 'async' : 'sync');
	croak "unknown callback mode $mode" unless $mode =~ /^(subproc|async|async2|sync)$/;
	my $host = hostname;
	my $workername = $args{workername} // "$self->{who} $host $0 $$";
	
	croak "already have action $method" if $self->actions->{$method};
	
	my $err;
	$self->ioloop->delay( #->steps(
	sub {
		my $d = shift;
		# fixme: check results?
		$self->conn->call('rpcswitch.announce', {
				 workername => $workername,
				 method => $method,
				 (($args{filter}) ? (filter => $args{filter}) : ()),
				 (($args{doc}) ? (doc => $args{doc}) : ()),
			}, $d->begin(0));
	},
	sub {
		#say 'call returned: ', Dumper(\@_);
		my ($d, $e, $r) = @_;
		if ($e) {
			$self->log->debug("announce got error " . Dumper($e));
			$err = $e->{message};
			return;
		}
		my ($res, $msg) = @$r;
		unless ($res) {
			$err = $msg;
			$self->log->error("announce got res: $res msg: $msg");
			return;
		}
		my $worker_id = $msg->{worker_id};
		my $action = {
			cb => $cb,
			mode => $mode,
			undocb => $args{undocb},
			meta => $args{meta},
			worker_id => $worker_id,
		};
		$self->actions->{$method} = $action;
		$self->rpc->register(
			$method,
			sub { $self->_magic($action, @_) },
			non_blocking => 1,
			raw => 1,
		);
		$self->log->debug("succesfully announced $method");
	})->catch(sub {
		($err) = @_;
		$self->log->debug("something went wrong with announce: $err");
	})->wait();

	return $err;
}

sub rpc_ping {
	my ($self, $c, $i, $rpccb) = @_;
	$self->lastping(time());
	return 'pong!';
}

sub _magic {
	#say '_magic: ', Dumper(\@_);
	my ($self, $action, $con, $request, $rpccb) = @_;
	my $method = $request->{method};
	my $req_id = $request->{id};
	unless ($action) {
		$self->log->info("_magic for unknown action $method");
		return;
	}
	my $rpcswitch = $request->{rpcswitch} or
		die "no rpcswitch information?";
	$rpcswitch->{worker_id} = $action->{worker_id};
	my $resp = {
		jsonrpc	    => '2.0',
		id	    => $req_id,
		rpcswitch   => $rpcswitch,
	};
	my $cb1 = sub {
		$resp->{result} = \@_;
		$rpccb->($resp);
	};
	my @args = ($req_id, $request->{params});
	push @args, $rpcswitch if $action->{meta};

	local $@;
	# fastest to slowest?
	if ($action->{mode} eq 'async2') {
		my $cb2 = sub {
			my $request = encode_json({
				jsonrpc => '2.0',
				method => 'rpcswitch.result',
				rpcswitch   => $rpcswitch,
				params => \@_,
			});
			$con->write($request);
		};
		eval {
			$action->{cb}->(@args, $cb1, $cb2);
		};
		if ($@) {
			$cb1->(RES_ERROR, $@);
		}
	} elsif ($action->{mode} eq 'async') {
		my $cb2 = sub {
			my $request = encode_json({
				jsonrpc => '2.0',
				method => 'rpcswitch.result',
				rpcswitch   => $rpcswitch,
				params => [ RES_OK, $req_id, @_ ],
			});
			$con->write($request);
		};
		eval {
			$action->{cb}->(@args, $cb2);
		};
		if ($@) {
			$cb1->(RES_ERROR, $@);
		} else {
			$cb1->(RES_WAIT, $req_id);
		}
	} elsif ($action->{mode} eq 'sync') {
		my @outargs = eval { $action->{cb}->(@args) };
		if ($@) {
			$cb1->(RES_ERROR, $@);
		} else {
			$cb1->(RES_OK, @outargs);
		}
	} elsif ($action->{mode} eq 'subproc') {
		my $cb2 = sub {
			my $request = encode_json({
				jsonrpc => '2.0',
				method => 'rpcswitch.result',
				rpcswitch   => $rpcswitch,
				params => $_[0], # fixme: \@_?
			});
			$con->write($request);
		};
		eval {
			$self->_subproc($cb2, $action, @args);
		};
		if ($@) {
			$cb1->(RES_ERROR, $@);
		} else {
			$cb1->(RES_WAIT, $req_id);
		}
	} else { 
		die "unkown mode $action->{mode}";
	}
}


sub _subproc {
	my ($self, $cb, $action, $req_id, @args) = @_;

	# based on Mojo::IOLoop::Subprocess
	my $ioloop = $self->ioloop;

	# Pipe for subprocess communication
	pipe(my $reader, my $writer) or die "Can't create pipe: $!";

	die "Can't fork: $!" unless defined(my $pid = fork);
	unless ($pid) {# Child
		$self->log->debug("in child $$");;
		$ioloop->reset;
		close $reader; # or we won't get a sigpipe when daddy dies..
		my $undo = 0;
		my @outargs = eval { $action->{cb}->($req_id, @args) };
		if ($@) {
			@outargs = ( RES_ERROR, $req_id, $@ );
		} else {
			unshift @outargs, (RES_OK, $req_id);
		}		
		print $writer Storable::freeze(\@outargs);
		$writer->flush;
		close $writer;
		# FIXME: normal exit?
		POSIX::_exit(0);
	}

	# Parent
	my $me = $$;
	close $writer;
	my $stream = Mojo::IOLoop::Stream->new($reader)->timeout(0);
	$ioloop->stream($stream);
	my $buffer = '';
	$stream->on(read => sub { $buffer .= pop });
	$stream->on(
		close => sub {
			#say "close handler!";
			return unless $$ == $me;
			waitpid $pid, 0;
			my $tmp = eval { Storable::thaw($buffer) };
			if ($@) {
				$tmp = [ RES_ERROR, $req_id, $@ ];
			}
			$self->log->debug('subprocess results: ' . Dumper($tmp));
			eval {
				$cb->($tmp)
			}; # the connection might be gone?
			$self->log->debug("got $@ writing subprocess results") if $@;
		}
	);
}


sub close {
	my ($self) = @_;
	$self->log->debug('closing connection');
	$self->conn->close();
	$self->ns->close();
	%$self = ();
}

# tick while Mojo::Reactor is still running and condition callback is true
sub _loop {
	warn __PACKAGE__." recursing into IO loop" if state $looping++;

	my $reactor = $_[0]->ioloop->reactor;
	my $err;

	if (ref $reactor eq 'Mojo::Reactor::EV') {

		my $active = 1;

		$active = $reactor->one_tick while $_[1]->() && $active;

	} elsif (ref $reactor eq 'Mojo::Reactor::Poll') {

		$reactor->{running}++;

		$reactor->one_tick while $_[1]->() && $reactor->is_running;

		$reactor->{running} &&= $reactor->{running} - 1;

	} else {

		$err = "unknown reactor: ".ref $reactor;
	}

	$looping--;
	die $err if $err;
}


#sub DESTROY {
#	my ($self) = @_;
#	say STDERR "destroying $self";
#}

1;

=encoding utf8

=head1 NAME

RPC::Switch::Client - Connect to the RPC-Switch using Mojo.

=head1 SYNOPSIS

  use RPC::Switch::Client;

   my $client = RPC::Switch::Client->new(
     address => ...
     port => ...
     who => ...
     token => ...
   );

   my ($status, $outargs) = $client->call(
     method => 'test',
     inargs => { test => 'test' },
   );

=head1 DESCRIPTION

L<RPC::Switch::Client> is a class to build a client to connect to the
L<RPC-Switch>.  The client can be used to initiate and inspect rpcs as well as
for providing 'worker' services to the RPC-Switch.

=head1 METHODS

=head2 new

$client = RPC::Switch::Client->new(%arguments);

Class method that returns a new RPC::Switch::Client object.

Valid arguments are:

=over 4

=item - address: address of the RPC-Switch.

(default: 127.0.0.1)

=item - port: port of the RPC-Switch

(default 6551)

=item - tls: connect using tls

(default false)

=item - tls_ca: verify server using ca

(default undef)

=item - tls_key: private client key

(default undef)

=item - tls_ca: public client certificate

(default undef)

=item - who: who to authenticate as.

(required)

=item - method: how to authenticate.

(default: password)

=item - token: token to authenticate with.

(required)

=item - debug: when true prints debugging using L<Mojo::Log>

(default: false)

=item - json: flag wether input is json or perl.

when true expects the inargs to be valid json, when false a perl hashref is
expected and json encoded.  (default true)

=item - ioloop: L<Mojo::IOLoop> object to use

(per default the L<Mojo::IOLoop>->singleton object is used)

=item - log: L<Mojo::Log> object to use

(per default a new L<Mojo::Log> object is created)

=item - timeout: how long to wait for Api calls to complete

(default 60 seconds)

=item - ping_timeout: after this long without a ping from the Api the
connection will be closed and the work() method will return

(default: 5 minutes)

=item - autoconnect: automatically connect to the RPC-Switch.

(default: true)

=back

=head2 connect

$connected = $client->connect();

Connect (or reconnect) to the RPC-Switch.  Returns a true value if the
connection succeeded.

=head2 is_connected

$connected = $client->is_connected();

Returns a true value if the $client is connected.

=head2 call

($status, $outargs) = $client->call(%args);

Calls the RPC-Switch and waits for the results.

Valid arguments are:

=over 4

=item - method: name of the method to call (required)

=item - inargs: input arguments for the workflow (if any)

=item - timeout: wait this many seconds for the method to finish
(optional, defaults to 5 times the Api-call timeout, so default 5 minutes)

=back

=head2 call_nb

$client->call_nb(%args);

Calls a method on the RPC-Switch and calls the provided callbacks on completion
of the method call.

=over 4

=item - waitcb: (optional) coderef that will be called when the worker
signals that processing may take a while.  The $wait_id can be used with the
get_status call, $status wil be the string 'RES_WAIT'.

( waitcb => sub { ($status, $wait_id) = @_; ... } )

=item - resultcb: coderef that will be called on method completion.  $status
will be a string value, one of 'RES_OK' or 'RES_ERROR'.  $outargs will be
the method return values or a error message, respectively.

( resultcb => sub { ($status, $outargs) = @_; ... } )

=back

=head2 get_status

($status, $outargs) = $client->get_status($wait_id,);

Retrieves the status for the given $wait_id.  See call_nb for a description
of the return values.

=head2 ping

$status = $client->ping($timeout);

Tries to ping the RPC-Switch. On success return true. On failure returns
the undefined value, after that the client object should be undefined.

=head2 announce

Announces the capability to perform a method to the RPC-Switch.  The
provided callback will be called when there is a method to be performed. 
Returns an error when there was a problem announcing the action.

  my $err = $client->announce(
    workername => 'me',
    method => 'do.something',
    cb => sub { ... },
  );
  die "could not announce $method?: $err" if $err;

See L<rpc-switch-worker> for an example.

Valid arguments are:

=over 4

=item - workername: name of the worker

(optional, defaults to client->who, processname and processid)

=item - method: name of the method

(required)

=item - cb: callback to be called for the method, default arguments are
the request_id and the contents of the JSON-RPC 2.0 params field.

(required)

=item - mode: callback mode

(optional, default 'sync')

Possible values:

=over 8

=item - 'sync': simple blocking mode, just return the results from the
callback.  Use only for callbacks taking less than (about) a second.

=item - 'subproc': the simple blocking callback is started in a seperate
process.  Useful for callbacks that take a long time.

=item - 'async': the callback gets passed another callback as the last
argument that is to be called on completion of the task.  For advanced use
cases where the worker is actually more like a proxy.  The (initial)
callback is expected to return soonish to the event loop, after setting up
some Mojo-callbacks.

=back

=item - async: backwards compatible way for specifying mode 'async'

(optional, default false)

=item - meta: pass RPC-Switch meta information to the callback as an extra
argument after the JSON-RPC 2.0 params field.

=item - undocb: a callback that gets called when the original callback
returns an error object or throws an error.  Called with the same arguments
as the original callback.

(optional, only valid for mode 'subproc')

=item - filter: only process a subset of the method

The filter expression allows a worker to specify that it can only do the
method for a certain subset of arguments.  For example, for a "mkdir"
action the filter expression {'host' => 'example.com'} would mean that this
worker can only do mkdir on host example.com. Filter expressions are limited
to simple equality tests on one or more keys, and only those keys that are
allowed in the action definition. Filtering can be allowed, be mandatory or
be forbidden per action.

=item - doc: documentation for the method

The documentation provided to the RPC-Switch can be retrieved by calling the
rpcswitch.get_method_details method.  Documentation is 'free-form' but the
suggested format is something like:

 'doc' => {
   'description' => 'adds step to counter and returns counter; step defaults to 1',
   'outputs' => 'counter',
   'inputs' => 'counter, step'
 }

=back

=head2 work

  $client->work();

Starts the L<Mojo::IOLoop>.  Returns a non-zero value when the IOLoop was
stopped due to some error condition (like a lost connection or a ping
timeout).

=head3 Possible work() exit codes

The RPC::Switch:Client library currently defines the following exit codes:

	WORK_OK
	WORK_PING_TIMEOUT
	WORK_CONNECTION_CLOSED

=head2 stop

  $client->stop($exit);

Makes the work() function exit with the provided exit code.

=head1 REMOTE METHOD INFORMATION

Once a connection has been established to the RPC-Switch there are two
methods that can provide information about the remote methods that are
callable via the RPC-Switch.


=over 4

=item - B<rpcswitch.get_methods>

Produces a list of all methods that are callable by the current role with a
short description text if available

Example:
  ./rpc-switch-client rpcswitch.get_methods '{}'

  ...
	[
	  {
	    'foo.add' => 'adds 2 numbers'
	  },
	  {
	    'foo.div' => 'undocumented method'
	  },
	  ...
	];

=item - B<rpcswitch.get_method_details>

Gives detailed information about a specific method.  Details can include the
'backend' (b) method that a worker needs to provide, a short descrption (d)
and contact information (c).  If a worker is available then the documentation
for that method from that worker is shown.

Example:
  ./rpc-switch-client rpcswitch.get_method_details '{"method":"foo.add"}'

  ...
	{
	  'doc' => {
		     'description' => 'adds step to counter and returns counter; step defaults to 1',
		     'outputs' => 'counter',
		     'inputs' => 'counter, step'
		   },
	  'b' => 'bar.add',
	  'd' => 'adds 2 numbers',
	  'c' => 'wieger'
	}

=back

=head1 SEE ALSO

=over 4

=item *

L<Mojo::IOLoop>, L<Mojo::IOLoop::Stream>, L<http://mojolicious.org>: the L<Mojolicious> Web framework

=item *

L<examples/rpc-switch-client>, L<examples/rpc-switch-worker>

=back

L<https://github.com/a6502/rpc-switch>: RPC-Switch

=head1 ACKNOWLEDGEMENT

This software has been developed with support from L<STRATO|https://www.strato.com/>.
In German: Diese Software wurde mit Unterstützung von L<STRATO|https://www.strato.de/> entwickelt.

=head1 AUTHORS

=over 4

=item *

Wieger Opmeer <wiegerop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Wieger Opmeer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
