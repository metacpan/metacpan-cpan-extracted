# Lightweight client for the RPC-Switch json-rpc request multiplexer
#
# see: RPC::Switch: https://github.com/a6502/rpc-switch 
#      RPC::Switch::Client: https://metacpan.org/pod/RPC::Switch::Client
#
package RPC::Switch::Client::Tiny;

use strict;
use warnings;
use Carp 'croak';
use JSON;
use IO::Select;
use IO::Socket::SSL;
use Time::HiRes qw(time);
use RPC::Switch::Client::Tiny::Error;
use RPC::Switch::Client::Tiny::Netstring;
use RPC::Switch::Client::Tiny::Async;
use RPC::Switch::Client::Tiny::SessionCache;

our $VERSION = '1.63';

sub new {
	my ($class, %args) = @_;
	my $s = $args{sock} or croak __PACKAGE__ . " expects sock";
	unless ($^O eq 'MSWin32') { # cpantester: strawberry perl does not support blocking() call
		defined(my $b = $s->blocking()) or croak __PACKAGE__ . " bad socket: $!";
		unless ($b) { croak __PACKAGE__ . " nonblocking socket not supported"; }
	}
	unless (exists $args{who}) { croak __PACKAGE__ . " expects who"; }
	my $self = bless {
		%args,
		id        => 1,  # next request id
		state     => '', # last rpcswitch.type
		reqs      => {}, # outstanding requests
		channels  => {}, # open rpcswitch channels
		methods   => {}, # defined worker methods
		announced => {}, # announced worker methods
	}, $class;
	if (ref($self->{sock}) eq 'IO::Socket::SSL') {
		$self->{auth_method} = 'clientcert' unless exists $self->{auth_method};
		$self->{token} = $self->{who} unless exists $self->{token}; # should be optional for clientcert
	} else {
		$self->{auth_method} = 'password' unless exists $self->{auth_method};
	}
	$self->{json_utf8} = $self->{client_encoding_utf8} ? {} : {utf8 => 1};
	return $self;
}

sub rpc_error {
	return RPC::Switch::Client::Tiny::Error->new(@_);
}

sub rpc_send {
	my ($self, $msg) = @_;
	my $s = $self->{sock};
	$msg->{jsonrpc} = '2.0';
	my $str = to_json($msg, {canonical => 1, %{$self->{json_utf8}}});
	$self->{trace_cb}->('SND', $msg) if $self->{trace_cb};
	return netstring_write($s, $str);
}

sub rpc_send_req {
	my ($self, $method, $msg) = @_;
	my $id = "$self->{id}"; $self->{id}++;
	$msg->{id} = $id;
	$msg->{method} = $method;
	$self->{reqs}{$id} = $method;
	$self->{state} = $method if $method =~ /^rpcswitch\./;
	$self->rpc_send($msg) or return;
	return $id;
}

sub rpc_send_call {
	my ($self, $method, $params, $reqauth) = @_;

	if (defined $reqauth) { # request authentication
		# Without the vcookie the rpcswitch does not validate
		# the reqauth parameter.
		# The vcookie 'eatme' value is hardcoded in the rpc-switch
		# code and is called 'channel information version'.
		#
		return $self->rpc_send_req($method, {params => $params, rpcswitch => {vcookie => 'eatme', reqauth => $reqauth}});
	} else {
		return $self->rpc_send_req($method, {params => $params});
	}
}

sub rpc_decode {
	my ($self, $msg) = @_;
	my ($req, $rsp) = ('', '');

	unless (($msg->{jsonrpc} eq '2.0') && (exists $msg->{id} || exists $msg->{method})) {
		die rpc_error('jsonrpc', "bad json-rpc: ".to_json($msg, {canonical => 1}));
	}
	if (exists $msg->{method}) {
		$req = $msg->{method};
	} elsif (!defined $msg->{id}) {
		die rpc_error('jsonrpc', "bad response id: ".to_json($msg, {canonical => 1}));
	} elsif (!exists $self->{reqs}{$msg->{id}}) {
		die rpc_error('jsonrpc', "unknown response $msg->{id}: ".to_json($msg, {canonical => 1}));
	} else {
		$rsp = delete $self->{reqs}{$msg->{id}};

		if (exists $msg->{error}) {
			die rpc_error('jsonrpc', "$rsp $msg->{id} response error: $msg->{error}{message}", {code => $msg->{error}{code}});
		}
		if (!exists $msg->{result}) {
			die rpc_error('rpcswitch', "$rsp $msg->{id} response error: result missing");
		}
		if ((ref($msg->{result}) ne 'ARRAY') && ($rsp ne 'rpcswitch.ping') && ($rsp ne 'rpcswitch.withdraw')) {
			die rpc_error('rpcswitch', "$rsp $msg->{id} bad response: $msg->{result}");
		}
	}
	return ($req, $rsp);
}

sub rpc_worker_announce {
	my ($self, $workername) = @_;

	# ignore repeated announce request or unfinished withdraw
	#
	return if (keys %{$self->{announced}});

	foreach my $method (keys %{$self->{methods}}) {
		next if exists $self->{methods}{$method}{id}; # active announce/withdraw request

		my $params = {method => $method, workername => $workername, doc => $self->{methods}{$method}{doc}};
		$params->{filter} = $self->{methods}{$method}{filter} if exists $self->{methods}{$method}{filter};
		my $id = $self->rpc_send_req('rpcswitch.announce', {params => $params});
		die rpc_error('io', 'netstring_write') unless defined $id;
		$self->{methods}{$method}{id} = $id;
	}
	return;
}

sub rpc_worker_withdraw {
	my ($self) = @_;

	# callers will get code -32006 'opposite end of channel gone'
	# errors when the announcement is withdrawn.
	#
	foreach my $method (keys %{$self->{announced}}) {
		next if exists $self->{methods}{$method}{id}; # active announce/withdraw request

		my $params = {method => $method};
		$params->{filter} = $self->{methods}{$method}{filter} if exists $self->{methods}{$method}{filter};
		my $id = $self->rpc_send_req('rpcswitch.withdraw', {params => $params});
		die rpc_error('io', 'netstring_write') unless defined $id;
		$self->{methods}{$method}{id} = $id;
	}
	return;
}

sub rpc_worker_flowcontrol {
	my ($self, $workername) = @_;

	# need to be in connected auth state
	return unless ($self->{state} && ($self->{state} ne 'rpcswitch.hello'));

	if ($self->{flowcontrol}) {
		my $cnt = (scalar keys %{$self->{async}{jobs}}) + (scalar @{$self->{async}{jobqueue}});
		#printf ">> flow: %d %d %d\n", $cnt, $self->{async}{max_async} * 2, $self->{async}{max_async};
		if ($cnt >= $self->{async}{max_async} * 2) {
			$self->rpc_worker_withdraw();
		} elsif ($cnt < $self->{async}{max_async}) {
			$self->rpc_worker_announce($workername);
		}
	}
	return;
}

sub valid_worker_err {
	my ($err) = @_;
	$err = {text => $err} unless ref($err); # convert plain errors
	$err->{class} = 'hard' unless exists $err->{class};
	return $err;
}

sub rpcswitch_resp {
	my ($rpcswitch) = @_;

	# Just the vcookie & vci-channel parameters are required by
	# the rpcswitch. The worker_id field is optional, and might
	# be set to the worker_id returned by the announce response.
	#
	$rpcswitch = {vcookie => $rpcswitch->{vcookie}, vci => $rpcswitch->{vci}};
	#$rpcswitch = {vcookie => $rpcswitch->{vcookie}, vci => $rpcswitch->{vci}, worker_id => $rpcswitch->{worker_id}};
	return $rpcswitch;
}

sub client {
	my ($self, $msg, $method, $params, $reqauth) = @_;
	my ($req, $rsp) = $self->rpc_decode($msg);

	if ($req eq 'rpcswitch.greetings') {
		my %token = $self->{token} ? (token => $self->{token}) : (); # should be optional for clientcert
		my $helloparams = {who => $self->{who}, %token, method => $self->{auth_method}};
		$self->rpc_send_req('rpcswitch.hello', {params => $helloparams});
	} elsif ($rsp eq 'rpcswitch.hello') {
		if (!$msg->{result}[0]) {
			die rpc_error('rpcswitch', "$rsp failed: $msg->{result}[1]");
		}
		$self->rpc_send_call($method, $params, $reqauth);
	} elsif ($rsp eq 'rpcswitch.ping') {
		return [$msg->{result}]; # ping complete
	} elsif ($rsp eq $method) {
		if (exists $msg->{rpcswitch}) { # internal rpcswitch methods have no channel
			$self->{channels}{$msg->{rpcswitch}{vci}} = 0; # wait for channel_gone
		}
		if ($msg->{result}[0] eq 'RES_WAIT') { # async worker notification (might use trace_cb to dump)
			$self->{channels}{$msg->{rpcswitch}{vci}} = $msg->{result}[1]; # msg id
		} elsif ($msg->{result}[0] eq 'RES_ERROR') { # worker error
			my $e = valid_worker_err($msg->{result}[1]);
			die rpc_error('worker', to_json($e), $e);
		} elsif ($msg->{result}[0] eq 'RES_OK') {
			return [@{$msg->{result}}[1..$#{$msg->{result}}]]; # client result[1..$]
		}
	} elsif ($req eq 'rpcswitch.result') {
		my $channel = $msg->{rpcswitch}{vci};
		if (($msg->{params}[0] eq 'RES_OK') && ($msg->{params}[1] eq $self->{channels}{$channel})) {
			return [@{$msg->{params}}[2..$#{$msg->{params}}]]; # client result[2..$] (notification)
		} elsif (($msg->{params}[0] eq 'RES_ERROR') && ($msg->{params}[1] eq $self->{channels}{$channel})) {
			my $e = valid_worker_err($msg->{params}[2]);
			die rpc_error('worker', to_json($e), $e);
		}
		die rpc_error('rpcswitch', "bad msg: $msg->{params}[0] $msg->{params}[1]");
	} elsif ($req eq 'rpcswitch.channel_gone') {
		my $channel = $msg->{params}{channel};
		if (exists $self->{channels}{$channel}) {
			my $id = delete $self->{channels}{$channel};
			die rpc_error('rpcswitch', "$req for request $id: $channel");
		}
		die rpc_error('rpcswitch', "$req for unknown request: $channel");
	} else {
		die rpc_error('rpcswitch', "unsupported msg: ".to_json($msg, {canonical => 1}));
	}
	return;
}

sub worker {
	my ($self, $msg, $workername) = @_;
	my ($req, $rsp) = $self->rpc_decode($msg);

	if ($req eq 'rpcswitch.greetings') {
		my %token = $self->{token} ? (token => $self->{token}) : (); # should be optional for clientcert
		my $helloparams = {who => $self->{who}, %token, method => $self->{auth_method}};
		$self->rpc_send_req('rpcswitch.hello', {params => $helloparams});
	} elsif ($rsp eq 'rpcswitch.hello') {
		if (!$msg->{result}[0]) {
			die rpc_error('rpcswitch', "$rsp failed: $msg->{result}[1]");
		}
		$self->rpc_worker_announce($workername);
	} elsif ($rsp eq 'rpcswitch.announce') {
		if (!$msg->{result}[0]) {
			die rpc_error('rpcswitch', "$rsp failed: $msg->{result}[1]");
		}
		my ($method) = grep { exists $self->{methods}{$_}{id} && $self->{methods}{$_}{id} eq $msg->{id} } keys %{$self->{methods}};
		if (!defined $method) {
			die rpc_error('rpcswitch', "unknown $rsp response $msg->{id}: $msg->{result}[1]");
		}
		# register announced method
		$self->{announced}{$method}{cb} = $self->{methods}{$method}{cb};
		$self->{announced}{$method}{worker_id} = $msg->{result}[1]{worker_id};
		delete $self->{methods}{$method}{id};
	} elsif ($req eq 'rpcswitch.ping') {
		$self->rpc_send({id => $msg->{id}, result => 'pong!'});
	} elsif (exists $self->{announced}{$req}) {
		$msg->{rpcswitch}{worker_id} = $self->{announced}{$req}{worker_id}; # save worker_id for response

		$self->{channels}{$msg->{rpcswitch}{vci}} = 0; # wait for channel_gone

		if ($self->{async}) { # use async call for forked childs
			$self->{async}->msg_enqueue($msg);
		} else {
			my $rpcswitch = rpcswitch_resp($msg->{rpcswitch});
			my @resp = eval { $self->{announced}{$req}{cb}->($msg->{params}, $msg->{rpcswitch}) };
			if ($@) {
				$self->rpc_send({id => $msg->{id}, result => ['RES_ERROR', $@], rpcswitch => $rpcswitch});
			} else {
				$self->rpc_send({id => $msg->{id}, result => ['RES_OK', @resp], rpcswitch => $rpcswitch});
			}
		}
	} elsif ($rsp eq 'rpcswitch.withdraw') {
		# Note: the rpcswitch sends just a boolean result here
		#
		if (!$msg->{result}) {
			die rpc_error('rpcswitch', "$rsp failed: $msg->{result}");
		}
		my ($method) = grep { exists $self->{methods}{$_}{id} && $self->{methods}{$_}{id} eq $msg->{id} } keys %{$self->{methods}};
		if (!defined $method) {
			die rpc_error('rpcswitch', "unknown $rsp response $msg->{id}: $msg->{result}");
		}
		# remove announced method
		delete $self->{announced}{$method};
		delete $self->{methods}{$method}{id};
	} elsif ($req eq 'rpcswitch.channel_gone') {
		my $channel = $msg->{params}{channel};
		if ($self->{async}) {
			my ($childs, $msgs) = $self->{async}->jobs_terminate('gone', sub { $_[0]->{rpcswitch}{vci} eq $channel });
			if (@$msgs) {
				warn "worker removed queued messages on channel gone: ".join(' ', map { $_->{id} } @$msgs);
			}
		}
		if (exists $self->{channels}{$channel}) {
			delete $self->{channels}{$channel};
		} else {
			warn "worker $req for unknown request: $channel";
		}
	} else {
		warn "worker unsupported msg: ".to_json($msg, {canonical => 1});
	}
	return;
}

sub is_session_req {
	my ($self, $params) = @_;
	return unless $self->{sessioncache};

	if (exists $params->{session} && exists $params->{session}{id}) {
		return $params->{session};
	}
	return;
}

sub is_session_resp {
	my ($self, $params) = @_;
	return unless $self->{sessioncache};

	if ((ref($params) eq 'ARRAY') && ($params->[0] eq 'RES_OK') && ref($params->[2]) && exists $params->[2]->{set_session}) {
		return $params->[2]->{set_session};
	}
	return;
}

sub child_handler {
	my ($self, $wr) = @_;

	# The child has to explicitly close the ssl-socket without shutdown.
	# Otherwise the parent will get an EOF.
	# see: https://metacpan.org/pod/IO::Socket::SSL#Common-Usage-Errors
	#
	if (ref($self->{sock}) eq 'IO::Socket::SSL') {
		$self->{sock}->close(SSL_no_shutdown => 1);
	} else {
		close($self->{sock});
	}
	$self->{sock} = $wr;
	delete $self->{trace_cb};
	local $SIG{INT} = 'DEFAULT';
	local $SIG{PIPE} = 'IGNORE'; # handle sigpipe via print/write result

	# When session handling is enabled a child might process
	# more than one request with the same session_id.
	#
	while (1) {
		my $b = eval { netstring_read($self->{sock}) };
		unless ($b) {
			next if ($@ && ($@ =~ /^EINTR/)); # interrupted
			die "worker child: $@" if $@;
			last; # EOF
		}
		my $msg = eval { from_json($b, {%{$self->{json_utf8}}}) };
		die "worker child: $@" if $@;

		# The client catches all possible die() calls, so that it is
		# guaranteed to call exit either from here or from a signal handler.
		#
		my $params;
		my $callback = $self->{methods}{$msg->{method}}{cb};
		my @resp;
		eval {
			local $SIG{PIPE} = 'DEFAULT'; # reenable sigpipe for worker code
			@resp = $callback->($msg->{params}, $msg->{rpcswitch});
		};
		if (my $err = $@) {
			$params = ['RES_ERROR', $msg->{id}, $err];
		} else {
			$params = ['RES_OK', $msg->{id}, @resp];
		}
		$b = eval { to_json($params, {%{$self->{json_utf8}}}) };
		return 1 if $@; # signal die from json encode
		my $res = netstring_write($self->{sock}, $b);
		return 2 unless $res; # signal socket error

		last unless $self->is_session_resp($params) || $self->is_session_req($msg->{params});
	}
	close($self->{sock}) or return 3; # signal errors like broken pipe
	return 0;
}

sub _worker_child_write {
	my ($self, $child, $msg) = @_;

	my $b = to_json($msg, {canonical => 1, %{$self->{json_utf8}}});
	my $res = netstring_write($child->{reader}, $b); # forward request to worker child
	die rpc_error('io', 'netstring_write') unless $res;
	return;
}

sub _worker_child_get {
	my ($self, $msg) = @_;

	# First try to reuse child for existing session
	#
	if (my $sessioncache = $self->{sessioncache}) {
		if (my $session_req = $self->is_session_req($msg->{params})) {
			if (my $child = $sessioncache->session_get($session_req->{id}, $msg->{id}, $msg->{rpcswitch}{vci})) {
				return $child;
			}
		} elsif ($sessioncache->{session_persist_user}) {
			if (exists $msg->{params}{$sessioncache->{session_persist_user}}) {
				my $user = $msg->{params}{$sessioncache->{session_persist_user}};
				if (my $child = $sessioncache->session_get_per_user($user, $msg->{id}, $msg->{rpcswitch}{vci})) {
					return $child;
				}
			}
		}
	}
	my $child = $self->{async}->child_start($self, $msg->{id}, $msg->{rpcswitch}{vci});
	return $child;
}

sub _worker_childs_dequeue_and_run {
	my ($self) = @_;

	while (my $msg = $self->{async}->msg_dequeue()) {
		my $id = $msg->{id};
		my $rpcswitch_resp = rpcswitch_resp($msg->{rpcswitch});

		my $child = eval { $self->_worker_child_get($msg) };
		unless ($@) {
			$self->{async}->job_add($child, $msg->{id}, {rpcswitch => $rpcswitch_resp});
			eval { $self->_worker_child_write($child, $msg) };
		}
		if ($@) {
			$self->rpc_send({id => $id, result => ['RES_ERROR', $@], rpcswitch => $rpcswitch_resp});
		} else {
			$self->rpc_send({id => $id, result => ['RES_WAIT', $id], rpcswitch => $rpcswitch_resp});
		}
	}
	return;
}

sub _worker_child_read_and_finish {
	my ($self, $child) = @_;

	my $res;
	my $b = eval { netstring_read($child->{reader}) };
	unless ($b) {
		my $err = $@ ? $@ : 'EOF';
		$res = $self->rpc_send({method => 'rpcswitch.result', params => ['RES_ERROR', $child->{id}, $err], rpcswitch => $child->{rpcswitch}});
		$self->{async}->child_finish($child, 'error');
	} else {
		my $params = eval { from_json($b, {%{$self->{json_utf8}}}) };
		if ($@) {
			$res = $self->rpc_send({method => 'rpcswitch.result', params => ['RES_ERROR', $child->{id}, $@], rpcswitch => $child->{rpcswitch}});
			$self->{async}->child_finish($child, 'error');
		} else {
			$res = $self->rpc_send({method => 'rpcswitch.result', params => $params, rpcswitch => $child->{rpcswitch}});

			if (my $sessioncache = $self->{sessioncache}) {
				if (my $set_session = $self->is_session_resp($params)) {
					$child->{session} = $sessioncache->session_new($set_session);
					$sessioncache->expire_insert($child->{session});
				}

				if ($sessioncache->session_put($child)) {
					my $cnt = scalar keys %{$sessioncache->{active}};
					if ($cnt > $sessioncache->{max_session}) {
						if ($child = $sessioncache->lru_dequeue()) {
							$self->{async}->child_finish($child, 'lru');
						}
					}
					$child = undef;
				} elsif (my $idle_child = $sessioncache->session_get_per_user_idle($child)) {
					# update idle user session with older session_id
					#
					$self->{async}->child_finish($idle_child, 'update');

					if ($sessioncache->session_put($child)) {
						$child = undef;
					}
				}
			}
			if ($child) {
				$self->{async}->child_finish($child, 'done');
			}
		}
	}
	return $res;
}

sub _worker_sessions_expire {
	my ($self) = @_;
	return unless $self->{sessioncache};

	# If a job for the expired session is active, the session
	# will be dropped when sesseion_put() is called after the
	# job completed.
	#
	while (my $child = $self->{sessioncache}->expired_dequeue()) {
		$self->{async}->child_finish($child, 'expired');
	}
	return;
}

sub rpc_timeout {
	my ($self, $call_timeout) = @_;

	if ($call_timeout && (keys %{$self->{reqs}} > 0)) {
		return $call_timeout; # for individual client call
	}
	return $self->{timeout};
}

sub rpc_stopped {
	my ($self) = @_;

	if ($self->{stop}) {
		if (($self->{stop} eq 'withdraw') && (keys %{$self->{announced}})) {
			return; # wait for withdraw to complete
		} elsif (($self->{stop} eq 'withdraw') && $self->{async} && (keys %{$self->{async}{jobs}})) {
			return; # wait for active jobs to complete
		}
		return 1;
	}
}

sub rpc_handler {
	my ($self, $call_timeout, $handler, @handler_params) = @_;

	# returns response or throws rpc_error.
	# returns undef when remote side cleanly closed connection with EOF.
	#
	while (!$self->rpc_stopped()) {
		my @pipes = ();
		if ($self->{async}) {
			$self->_worker_sessions_expire();
			$self->_worker_childs_dequeue_and_run() unless $self->{stop};
			$self->{async}->childs_reap(nonblock => 1);
			$self->rpc_worker_flowcontrol(@handler_params);
			@pipes = map { $_->{reader} } values %{$self->{async}{jobs}};
		}
		my $timeout = $self->rpc_timeout($call_timeout);

		if ($timeout || @pipes) {
			my @ready = IO::Select->new(($self->{sock}, @pipes))->can_read($timeout);
			next if (@ready == 0) && $!{EINTR}; # $! is not reset on success
			die rpc_error('jsonrpc', 'receive timeout') unless (@ready > 0);

			foreach my $fh (@ready) {
				if (($fh != $self->{sock}) && $self->{async}) {
					unless (exists $self->{async}{jobs}{$fh->fileno}) {
						die rpc_error('io', "child pipe not found: ". $fh->fileno);
					}
					my $child = $self->{async}{jobs}{$fh->fileno};
					$self->{async}->job_rem($child);
					my $res = $self->_worker_child_read_and_finish($child);
				}
			}
			next unless grep { $_ == $self->{sock} } @ready;
		}

		# always block on full messages from rpcswitch
		my $b = eval { netstring_read($self->{sock}) };
		unless ($b) {
			next if ($@ && ($@ =~ /^EINTR/)); # check if stopped
			die rpc_error('io', $@) if $@;
			return; # EOF
		}
		my $msg = eval { from_json($b, {%{$self->{json_utf8}}}) };
		die rpc_error('jsonrpc', $@) if $@;
		$self->{trace_cb}->('RCV', $msg) if $self->{trace_cb};
		my $res = eval { $handler->($self, $msg, @handler_params) };
		if (my $err = $@) {
			die $err if ref($err); # forward error
			die rpc_error('io', $err);
		}
		if ($res) {
			return $res;
		}
	}
	return; # STOP is checked by caller
}

sub work {
	my ($self, $workername, $methods, $opts) = @_;

	# a write on a shutdown socket should never happen
	#
	local $SIG{'PIPE'} = sub { die "work[$$]: got PIPE!\n" };

	foreach my $method (keys %$methods) {
		$self->{methods}{$method}{cb} = $methods->{$method}{cb};
		$self->{methods}{$method}{doc} = (defined $methods->{$method}{doc}) ? $methods->{$method}{doc} : {};
		$self->{methods}{$method}{filter} = $methods->{$method}{filter} if exists $methods->{$method}{filter};
	}
	$opts->{trace_cb} = $self->{trace_cb} if exists $self->{trace_cb};
	$self->{async} = RPC::Switch::Client::Tiny::Async->new(%$opts) if $opts->{max_async};
	$self->{flowcontrol} = $opts->{flowcontrol} if $opts->{flowcontrol};
	$self->{sessioncache} = RPC::Switch::Client::Tiny::SessionCache->new(%$opts) if $opts->{max_session};
	$self->rpc_handler(0, \&worker, $workername);

	if ($self->{stop}) {
		$self->rpc_worker_withdraw();
		$self->{stop} = 'withdraw';

		# wait some time for withdraw & active jobs to complete
		#
		local $SIG{ALRM} = sub { warn "worker child stop timeout\n"; $self->{stop} = 'timeout'; };
		alarm($self->{gracetime});
		$self->rpc_handler(0, \&worker, $workername);
		alarm(0);
		die rpc_error('io', 'STOP');
	}
	if (my $async = $self->{async}) {
		# drop stored sessions
		#
		if (my $sessioncache = $self->{sessioncache}) {
			foreach my $session_id (keys %{$sessioncache->{active}}) {
				if (my $child = $sessioncache->session_get($session_id)) {
					$async->child_finish($child, 'idle');
				}
			}
		}
		# reap remaining childs
		#
		if (keys %{$async->{finished}}) {
			local $SIG{ALRM} = sub { warn "worker child wait timeout\n" };
			alarm(1); # wait at most for one second
			unless ($async->childs_reap()) { # blocking
				$async->childs_reap(nonblock => 1); # continue nonblocking after timeout
			}
			alarm(0);
		}

		# EOF is only an error here when there are outstanding requests
		#
		my ($stopped, $msgs) = $async->jobs_terminate('stopped', sub { 1 });
		my @childs = keys %{$async->{finished}};

		$async->childs_kill(); # don't wait here

		$async->{jobqueue} = [];
		$async->{finished} = {};

		die rpc_error('io', 'eof while jobs active: '.join(' ', @childs)) if (@childs);
		die rpc_error('io', 'eof while jobs queued: '.join(' ', @$msgs)) if (@$msgs);
	}
	return;
}

sub call {
	my ($self, $method, $params, $opts) = @_;
	my $reqauth = $opts->{reqauth};
	my $call_timeout = $opts->{timeout};

	if ($self->{state} eq 'rpcswitch.hello') { # trigger rpc_send for consecutive requests
		$self->rpc_send_call($method, $params, $reqauth);
	}
	# EOF is an error here (response missing)
	#
	my $res = $self->rpc_handler($call_timeout, \&client, $method, $params, $reqauth) or die rpc_error('io', 'eof');
	return wantarray() ? @$res : $res->[0];
}

# stop() exits an active $client->work() worker handler.
#
# - work() dies with RPC::Switch::Client::Tiny::Error which
#   might be {type => 'io', message => 'STOP'}, or any other
#   error if a non-restartable system call was interrupted.
#
#   - stop() makes no sense for call() (it has rpc_timeout)
#   - the only way to call stop is from a signal handler.
#   - if a signal handler is called, non-restartavle perl
#     system call are interrupted and return $! == EINTR.
#
#   -> this can break an active worker handler and result in
#      a RES_ERROR-message to the caller if a non-restartable
#      perl syscall is interrupted.
#   -> for the async worker mode this should mostly work.
#      (sysreadfull, rpc print & IO::Select are restartable).
#   -> stop will just wait for a gracetime of 2 seconds
#      for active jobs to complete. The remaining jobs
#      are terminated.
#
sub stop {
	my ($self, $opts) = @_;
	$self->{gracetime} = $opts->{gracetime} ? $opts->{gracetime} : 2;
	$self->{stop} = 'pending';
	return;
}

# The perl object destroy order is undefined, so $self->{sock}
# might already be destroyed and it makes no sense to try to
# send RES_ERROR messages for remaining childs.
# see: https://perldoc.perl.org/perlobj#Global-Destruction
#
# So just terminate remaining childs, and let init-process 
# collect them instead of calling waitpid() here.
#
# TODO: perl will call DESTROY only when the process exits
#       cleanly or calls exit(). If the process is killed, perl
#       calls DESTROY only if a handler for the matching signal
#       is installed, like: $SIG{'TERM'} = sub { exit; };
#
#       -> so does it make sense to support DESTROY at all,
#          if there are situations when it is not called?
#
sub DESTROY {
	my ($self) = @_;
	$self->{async}->childs_kill() if $self->{async}; # don't wait here
}

1;

__END__

=head1 NAME

RPC::Switch::Client::Tiny - Lightweight client for the RPC-Switch.

=head1 SYNOPSIS

  use RPC::Switch::Client::Tiny;

  # init rpcswitch client
  my $s = IO::Socket::SSL->new(PeerAddr => $host, Proto => 'tcp', Timeout => 30,
	SSL_cert_file => $cert_file, SSL_key_file => $key_file,
	SSL_verify_mode => SSL_VERIFY_PEER, SSL_ca_file => $ca_file);

  sub trace_cb {
	my ($type, $msg) = @_;
	printf "%s: %s\n", $type, to_json($msg, {pretty => 0, canonical => 1});
  }

  my $client = RPC::Switch::Client::Tiny->new(sock => $s, who => $who, timeout => 60, trace_cb => \&trace_cb);

  # call rpcswitch worker
  my $res = $client->call('test.ping', {val => 'test'}, $options);

  # run rpcswitch worker
  sub ping_handler {
	my ($params, $rpcswitch) = @_;
	return {success => 1, msg => "pong $params->{val}"};
  }

  my $methods = {
	'test.ping' => {cb => \&ping_handler, doc => $doc},
	'test.tick' => {cb => \&tick_handler}
  }
  $client->work($workername, $methods, $options);

=head1 DESCRIPTION

RPC::Switch::Client::Tiny is a lightweight RPC-Switch client.

This module works on a single socket connection, and has no
dependencies on the Mojo framework like the L<RPC::Switch::Client>
module.

The rpctiny tool included in the examples directory shows how to
configure and call a worker handler using a local installation
of the rpc-switch server.

=head2 References

The implementation is based on the following protocols:

- json-rpc 2.0: L<https://www.jsonrpc.org/specification>

- netstring proto: L<http://cr.yp.to/proto/netstrings.txt>

- rpc-switch: L<https://github.com/a6502/rpc-switch>

=head2 Error Handling

The L<RPC::Switch::Client::Tiny::Error> always contains a 'type' and
a 'message' field. It might contain additional fields depending
on the error type: 

  my $res = eval { $client->call($method, $params, $options) };
  if (my $err = $@) { 
      die "client $err->{type} error[$err->{code}]: $err->{message}" if $err->{type} eq 'jsonrpc';
      die "client $err->{type} error[$err->{class}]: $err->{message}" if $err->{type} eq 'worker';
      die "client $err");
  }

  type 'jsonrpc': 'code':  jsonprc error returned by the rpcswitch 
  type 'worker':  'class': hard/soft
                  'name':  somthing like BACKEND_ERROR
                  'text':  detailed error message
                  'from':  sinding module
                  'data':  additional error information

=head2 Encoding

All methods expect and return strings in utf8-format, when the option
client_encoding_utf8 is enabled.

To pass latin1-strings as parameter, a caller would have to convert
the input first. (see: $utf8 = Encode::encode('utf8', $latin1)).

The json-rpc messages are also utf8-encoded when they are transmitted.
(see: L<https://metacpan.org/pod/JSON#utf8>)

Without the client_encoding_utf8 option, all passed strings are utf8-encoded
for the json-rpc transmission, because the client character-encoding is
assumed to be unknown. This might transmit doubly utf8-encoded strings.

=head2 Async handling

When $client->work() is called with a value of max_async > 0, then
the rpc_handler will fork for each request from a caller and use
use pipes for the synchronization with the childs.

This works like this:

  1) parent opens a pipe and sends RES_WAIT after the child forked.
  2) the child calls the worker-handler and writes RES_OK/RES_ERROR to the pipe.
  3) the parent rpc_handler() reads from the pipe and forwards the
     message to the rpcswitch caller. It closes the pipe afterwards.
  4) if the child dies or no valid result can be read from the pipe,
     the parent sends a RES_ERROR message to the rpcswitch caller. 

=head2 Session Cache

When session handling is enabled a child might process more than
one request with the same session_id.

The session handling is loosely based on the HTTP Set-Cookie/Cookie
Mechanism described in RFC 6265, and uses json paramters instead of
http-headers. (see: L<https://datatracker.ietf.org/doc/html/rfc6265>)

- the worker signals a set_session request via:

  $params = {.., set_session => {id => $id, expires => $iso8601}}

- the caller signals a session request via:

  $params = {.., session => {id => $id}}

Just one active child is used for each session_id, and the child
can handle just one request at a time. If the child for a session
is busy, a new child without session support will be used for the
request.

=head2 Caller Retry Handling

A caller should be able to distinguish between hard errors and
errors where a later retry is possible because the service is
currently not available. These are for example:

  1) Socket connect-timeouts because the rpcswitch or the
     network is not available.
     (socket connect $@: Connection refused)
  2) The rpcswitch socket closes.
     (io error: eof)
  3) No Worker is currently available for method.
     (jsonrpc error -32003: No worker available for $method)
  4) The Worker terminates for an active request (got RES_WAIT)
     (rpcswitch error: rpcswitch.channel_gone for request)
  5) The Worker terminates for a queued request
     (jsonrpc error -32006: opposite end of channel gone)
  6) The callers Request Timeout expires
     (jsonrpc error: receive timeout)

If more than one worker is running, and only a single worker
terminates, it could be useful to retry operations immediately.

TODO: consolidate error codes to allow better match on 'timeout'?

=head2 Flow Control

Since the communication with the rpcswitch uses a single
socket, the socket can't be used for flowcontrol. All
incoming worker requests have to be queued, so that the
socket is available for other protocol messages.

In normal operation the worker jobqueue could grow to a very
large size, if clients add new requests faster than they can
be handled.

If $client->{work} is called with the {flowcontrol => 1} option,
the worker will withdraw its methods when it runs in async mode
and the jobqueue reaches the hiwater mark. When the jobqueue
size falls below the lowater mark, all methods will be announced
again.

The client will see the 'channel gone' messages (4) and (5) if
a method is withdrawn because of flowcontrol , and can retry the
operation later.

=head1 METHODS

=head2 new

  $client = RPC::Switch::Client::Tiny->new(sock => $s, who => $w, %args);

The new contructor returns a RPC::Switch::Client::Tiny object.
Arguments are passed in key => value pairs.

The only required arguments are `sock` and `who`.

The client is responsible to pass a connected socket to ->new()
and to close the socket after all client-calls are complete.

The new constructor dies when arguments are invalid, or if required
arguments are missing.

The accepted arguments are:

=over 4

=item sock: connected socket (error if nonblocking) (required)

=item who: rpcswitch client name (required)

=item auth_method: optional (defaults to 'password' or 'clientcert')

=item token: token for auth_method 'password' (optional for 'clientcert')

=item client_encoding_utf8: all client strings are in utf8-format

=item timeout: optional rpc-request timeout (defaults to 0 (unlimited))

=item trace_cb: optional handler to log SND/RCV output

=back

The trace_cb handler is called with a message 'type' indicating
the direction of a message, and with a 'msg' object containing
the decoded 'json-rpc' message:

  sub trace_cb {
	my ($type, $msg) = @_;
	printf "%s: %s\n", $type, to_json($msg, {pretty => 0, canonical => 1});
  }

=head2 call

  $res = $client->call($method, $params, $options);

Calls a method of a rpcswitch worker and waits for the result.

On success the result from a rpcswitch RES_OK response is returned.

On failure the method dies with a L<RPC::Switch::Client::Tiny::Error>.
When the method call is trapped with eval, the error object is
returned in '$@'.

The arguments are:

=over 4

=item method: worker method to call like: 'test.ping'

=item params: request params like: {val => 'test'}

=item options->{reqauth}: optional rpcswitch request authentication

=item options->{timeout}: optional per call timeout

=back

=head2 work

  $client->work($workername, $methods, $options);

Runs the passed rpcswitch worker methods.

Dies with L<RPC::Switch::Client::Tiny::Error> on failure.

Returns without die() only when the remote side cleanly closed the
connection, and there are no outstanding requests ($@ == '' for eval).

=over 4

=item workername: name of the worker

=item methods: worker methods to announce

=item options->{max_async}: run multiple forked workers using async RES_WAIT notification

=item options->{flowcontrol}: announce/withdraw async methods based on load

=item options->{max_session}: enable session cache for async worker childs

=item options->{session_expire}: default session expire time in seconds

=item options->{session_idle}: session idle time in seconds for user session updates

=item options->{session_persist_user}: reuse active user sessions for given user param

=item options->{max_user_session}: limit session cache per optional user field

=back

The options are described in their respective sections unter DESCRIPTION.

The methods parameter defines the worker methods, which are
announced to the rpcswitch. Each method is passed as a
'method_name => $method_definition' tupel.

The valid fields of the $method_definition are:

=over 4

=item cb: method handler (required)

=item doc: optional documentation for method

=item filter: optional filter to restrict method subset of params

=back

The provided handler is called when the method is called via
the rpcswitch.

  sub ping_handler {
	my ($params, $rpcswitch) = @_;
	return {success => 1, msg => "pong $params->{val}"};
  }

  my $methods = {
	'test.ping' => {cb => \&ping_handler, doc => $doc},
	'test.tick' => {cb => \&tick_handler}
  }

The optional documentation provided to the rpcswitch can be retrieved
by calling the rpcswitch.get_method_details method. The format of the
documentation field is:

  doc => {
	description => 'send a ping', inputs => 'val' outputs => 'msg',
  }

The optional filter expression allows a worker to specify that it can
process the method only for a certain subset of the method parameters.
For example the filter expression {'host' => 'example.com'} would mean
that the worker can only handle method calls with a matching params field.

Filter expressions are limited to simple equality tests on one or more keys.
These keys have to be configured in in the rpcswitch action definition,
and can be allowed, mandatory or forbidden per action.

=head1 SEE ALSO

Used submodules for Error object L<RPC::Switch::Client::Tiny::Error>,
Netstring messages L<RPC::Switch::Client::Tiny::Netstring>,
Async child handling L<RPC::Switch::Client::Tiny::Async> and
Session cache L<RPC::Switch::Client::Tiny::SessionCache>.

JSON encoder/decoder L<JSON>

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Barnim Dzwillo

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

