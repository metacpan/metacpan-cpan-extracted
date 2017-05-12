
package Net::OpenSSH::Parallel;

our $VERSION = '0.14';

use strict;
use warnings;
use Carp qw(croak carp);
our @CARP_NOT=qw(Net::OpenSSH);

use Net::OpenSSH;
use Net::OpenSSH::Parallel::Constants qw(:error :on_error);

use POSIX qw(WNOHANG);
use Time::HiRes qw(time);
use Scalar::Util qw(dualvar);

our $debug;

sub new {
    my ($class, %opts) = @_;
    my $max_workers = delete $opts{workers};
    my $max_conns = delete $opts{connections};
    my $reconnections = delete $opts{reconnections};
    my $on_error = delete $opts{on_error};

    if ($max_conns) {
	if ($max_workers) {
	    $max_conns < $max_workers and
		croak "connections ($max_conns) < workers ($max_workers)";
	}
	else {
	    $max_workers = $max_conns;
	}
    }

    %opts and croak "unknonwn option(s): ". join(", ", keys %opts);

    my $self = { joins => {},
		 hosts => {},
		 host_by_pid => {},
		 ssh_master_by_pid => {},
		 in_state => {
			      connecting => {},
			      ready => {},
			      running => {},
			      done => {},
			      waiting => {},
			      suspended => {},
			      join_failed => {},
			     },
		 connected => { suspended => {},
				waiting => {},
				join_failed => {},
			      },
		 joins => {},
		 max_workers => $max_workers,
		 max_conns => $max_conns,
		 num_conns => 0,
		 reconnections => $reconnections,
		 on_error => $on_error,
	       };
    bless $self, $class;
    $self;
}

my %debug_channel = (api => 1, state => 2, select => 4, at => 8,
		     action => 16, join => 32, workers => 64,
		     connect => 128, conns => 256, error => 512);

sub _debug {
    my $channel = shift;
    my $bit = $debug_channel{$channel}
	or die "internal error: bad debug channel $channel";
    if ($debug & $debug_channel{$channel}) {
	print STDERR sprintf("%6.3f", (time - $^T)), "| ",
	    join('', map { defined($_) ? $_ : '<undef>' } @_), "\n";
    }
}

sub add_host {
    my $self = shift;
    my $label = shift;
    $label =~ /([,*!()<>\/{}])/ and croak "invalid char '$1' in host label";
    my %opts = (@_ & 1 ? (host => @_) : @_);
    $opts{host} = $label unless defined $opts{host};
    $opts{batch_mode} = 1 unless defined $opts{batch_mode};

    my $on_error = delete $opts{on_error};
    my $reconnections = delete $opts{reconnections};

    my $host = { label => $label,
		 workers => 1,
		 opts => \%opts,
		 ssh => undef,
		 state => 'done',
		 queue => [],
		 on_error => $on_error,
		 reconnections => $reconnections,
	       };

    $self->{hosts}{$label} = $host;
    $debug and _debug(api => "[$label] added ($host)");
    $self->{in_state}{done}{$label} = 1;
    $debug and _debug(state => "[$label] state set to done");
}

sub _set_host_state {
    my ($self, $label, $state) = @_;
    my $host = $self->{hosts}{$label};
    my $old = $host->{state};
    delete $self->{in_state}{$old}{$label}
	or die "internal error: host $label is in state $old but not in such queue";
    delete $self->{connected}{$old}{$label}
	if ($old eq 'suspended' or $old eq 'waiting' or $old eq 'join_failed');

    $self->{in_state}{$state}{$label} = 1;
    $host->{state} = $state;
    $debug and _debug(state => "[$label] state changed $old --> $state");

    if ($host->{ssh} and ($state eq 'suspended' or
			  $state eq 'waiting' or
			  $state eq 'join_failed')) {
	$self->{connected}{$state}{$label} = 1;
	$debug and _debug(state => "[$label] host is connected");
    }
}

my %sel2re_cache;

sub _selector_to_re {
    my ($self, $part) = @_;
    $sel2re_cache{$part} ||= do {
	$part = quotemeta $part;
	$part =~ s/\\\*/.*/g;
	qr/^$part$/;
    }
}

sub _select_labels {
    my ($self, $selector) = @_;
    my %sel;
    my @parts = split /\s*,\s*/, $selector;
    for (@parts) {
	my $re = $self->_selector_to_re($_);
	$sel{$_} = 1 for grep $_ =~ $re, keys %{$self->{hosts}};
    }
    my @labels = keys %sel;
    $debug and _debug(select => "selector($selector) --> [", join(', ', @labels), "]");
    return @labels;
}

sub all { shift->push('*', @_) }

my %push_action_alias = (get  => 'scp_get',
                         put  => 'scp_put',
                         psub => 'parsub',
                         cmd  => 'command');

my %push_min_args = ( here      => 1,
                      goto      => 1,
                      stop      => 0,
                      sub       => 1,
                      parsub    => 1,
                      scp_get   => 2,
                      scp_put   => 2,
                      rsync_get => 2,
                      rsync_put => 2 );

my %push_max_args =  ( here     => 1,
                       goto     => 1,
                       stop     => 0 );

sub push {
    my $self = shift;
    my $selector = shift;
    my $action = shift;
    my $in_state = $self->{in_state};

    if (ref $action eq 'CODE') {
	unshift @_, $action;
	$action = 'sub';
    }

    my $alias = $push_action_alias{$action};
    $action = $alias if defined $alias;

    $action =~ /^(?:command|(?:(?:rsync|scp)_(?:get|put))|join|sub|parsub|here|stop|goto|_notify|connect)$/
	or croak "bad action '$action'";

    my %opts = (($action ne 'sub' and ref $_[0] eq 'HASH') ? %{shift()} : ());
    %opts and grep($action eq $_, qw(join here))
        and croak "unsupported option(s) '" . join("', '", keys %opts) . "' in $action action";

    my @labels = $self->_select_labels($selector);

    my $max = $push_max_args{$action};
    croak "too many parameters for action $action"
        if (defined $max and $max < @_);

    my $min = $push_min_args{$action};
    croak "too few parameters for action $action"
        if (defined $min and $min > @_);

    if ($action eq 'join') {
	my $notify_selector = shift @_;
	my $join = { id => '#' . $self->{join_seq}++,
		     depends => {},
		     notify => [] };
	my @depends = $self->push($notify_selector, _notify => {}, $join)
	    or do {
		$join->_debug(join => "join $join->{id} does not depend on anything, ignoring!");
		return ();
	    };
	$join->{depends}{$_} = 1 for @depends;

	for my $label (@labels) {
	    my $host = $self->{hosts}{$label};
	    push @{$host->{queue}}, [join => {}, $join];
	    $debug and _debug(api => "[$label] join $join->{id} queued");
	    $self->_set_host_state($label, 'ready')
		if $in_state->{done}{$label};
	}
    }
    else {
	for my $label (@labels) {
	    my $host = $self->{hosts}{$label};
	    push @{$host->{queue}}, [$action, \%opts, @_];
	    $debug and _debug(api => "[$label] action $action queued");
	    $self->_set_host_state($label, 'ready')
		if $in_state->{done}{$label};
	}
    }
    @labels;
}

sub _audit_conns {
    my $self = shift;
    my $hosts = $self->{hosts};
    my $num = 0;
    $num++ for grep $_->{ssh}, values %$hosts;
    $debug and _debug(conns => "audit_conns counted: $num, saved: $self->{num_conns}");
    $num == $self->{num_conns}
	or die "internal error: wrong number of connections, counted: $num, saved: $self->{num_conns}";
    my $in_state = $self->{in_state};
    for my $state (keys %$in_state) {
	my $num = 0;
	$num++ for grep $hosts->{$_}{ssh}, keys %{$in_state->{$state}};
	my $total = keys %{$in_state->{$state}};
	print STDERR "conns in state $state: $num of $total\n";
    }
}

sub _hash_chain_get {
    my $name = shift;
    for (@_) {
	if (defined $_) {
	    my $v = $_->{$name};
	    return $v if defined $v;
	}
    }
    undef;
}

sub _at_error {
    my ($self, $label, $error) = @_;
    my $host = $self->{hosts}{$label};
    my $task = delete $host->{current_task};
    my $queue = $host->{queue};

    $debug and _debug(error => "_at_error label: $label, error: $error");

    my $opts;
    $opts = $task->[1] if $task;

    my $on_error;
    if ($error == OSSH_MASTER_FAILED) {
        if ($host->{state} eq 'connecting') {
            # task is not set in state connecting!
            $task and die "internal error: task is defined in state connecting";
            $opts = $queue->[0][1] if @$queue;
        }
	my $max_reconnections = _hash_chain_get(reconnections => $opts, $host, $self) || 0;
	my $reconnections = $host->{current_task_reconnections}++ || 0;
	$debug and _debug(error => "[$label] reconnection: $reconnections, max: $max_reconnections");
	if ($reconnections < $max_reconnections) {
	    $debug and _debug(error => "[$label] will reconnect!");
	    $on_error = OSSH_ON_ERROR_RETRY;
	}
    }
    $on_error ||= _hash_chain_get(on_error => $opts, $host, $self);

    if (ref $on_error eq 'CODE') {
	if ($error == OSSH_JOIN_FAILED) {
	    $on_error = $on_error->($self, $label, $error);
	}
	else {
	    $on_error = $on_error->($self, $label, $error, $task);
	}
    }

    $on_error = OSSH_ON_ERROR_ABORT if (not defined $on_error or
                                        $error == OSSH_ABORTED);

    $debug and _debug(error => "[$label] on_error (final): $on_error, error: $error (".($error+0).")");

    if ($on_error == OSSH_ON_ERROR_RETRY) {
	if ($error == OSSH_MASTER_FAILED) {
	    $self->_set_host_state($label, 'suspended');
	    $self->_disconnect_host($label);
	    $self->_set_host_state($label, 'ready');
	}
	elsif ($error == OSSH_GOTO_FAILED) {
            # No way to retry after a GOTO error!
            # That should probably croak, but that would leave unmanaged
            # processes running
            $on_error = OSSH_ON_ERROR_ABORT;
        }
        else {
	    unshift @$queue, $task;
	}
	return;
    }

    delete $host->{current_task_reconnections};

    if ($on_error == OSSH_ON_ERROR_IGNORE) {
	if ($error == OSSH_MASTER_FAILED) {
	    # establishing a new connection failed, what we should do?
	    # currently we remove the current task from the queue and
	    # continue.
	    shift @$queue unless $task;
	    $self->_set_host_state($label, 'suspended');
	    $self->_disconnect_host($label);
	    $self->_set_host_state($label, 'ready');
	}
        else {
	    $self->_set_host_state($label, 'ready');
        }
	# else do nothing
    }
    else {
        unless ($on_error == OSSH_ON_ERROR_DONE or
                $on_error == OSSH_ON_ERROR_ABORT or
                $on_error == OSSH_ON_ERROR_ABORT_ALL) {
            carp "bad on_error code $on_error";
            $on_error = OSSH_ON_ERROR_ABORT;
        }
	my $queue = $host->{queue};
	my $failed = ($on_error != OSSH_ON_ERROR_DONE);
	$debug and _debug(error => "[$label] dropping queue, ", scalar(@$queue), " jobs");
	while (my $task = shift @$queue) {
	    my ($action, undef, $join) = @$task;
	    $debug and _debug(error => "[$label] remove action $action from queue");
	    $self->_join_notify($label, $join, $failed)
		if $action eq '_notify';
	}

 	$on_error == OSSH_ON_ERROR_ABORT_ALL
 	    and $self->{abort_all} = 1;

	$self->_set_host_state($label, 'done');
	$self->_disconnect_host($label);
	$host->{error} = $error;
    }
}

sub _at_connect {
    my ($self, $label) = @_;
    my $host = $self->{hosts}{$label};
    $debug and _debug(connect => "[$label] _connect, starting SSH connection");
    $host->{ssh} and die "internal error: connecting host is already connected";
    my $ssh = $host->{ssh} = Net::OpenSSH->new(expand_vars => 1,
					       %{$host->{opts}},
					       async => 1);
    $ssh->set_var(LABEL => $label);
    my $master_pid = $ssh->get_master_pid;
    $host->{master_pid} = $master_pid;
    $self->{ssh_master_by_pid}{$master_pid} = $label;
    $self->{num_conns}++;
    $self->_set_host_state($label, 'connecting');
    if ($ssh->error) {
	$self->_at_error($label, $ssh->error);
    }
}

sub _at_connecting {
    my ($self, $label) = @_;
    my $host = $self->{hosts}{$label};
    $debug and _debug(at => "[$label] at_connecting, waiting for master");
    my $ssh = $host->{ssh};
    if ($ssh->wait_for_master(1)) {
	$debug and _debug(at => "[$label] at_connecting, master connected");
	$self->_set_host_state($label, 'ready');
    }
    elsif ($ssh->error) {
	$self->_at_error($label, $ssh->error);
    }
}

sub _join_notify {
    my ($self, $label, $join, $failed) = @_;
    # use Data::Dumper;
    # print STDERR Dumper $join;
    delete $join->{depends}{$label}
	or die "internal error: $join->{id} notified for non dependent label $label";
    $debug and _debug(join => "removing dependent $label from join $join->{id}");
    $join->{failed} = 1 if $failed;
    if (not %{$join->{depends}}) {
	$debug and _debug(join => "join $join->{id} done");
	$join->{done} = 1;
	my $failed = $join->{failed};
	for my $label (@{$join->{notify}}) {
	    $debug and _debug(join => "notifying $label about join $join->{id} done");
	    $self->_set_host_state($label, $failed ? 'join_failed' : 'ready');
	}
    }
    # print STDERR Dumper $join;
}

sub _num_workers {
    my $in_state = shift->{in_state};
    ( keys(%{$in_state->{ready}}) +
      keys(%{$in_state->{running}}) +
      keys(%{$in_state->{connecting}}) );
}

sub _disconnect_host {
    my ($self, $label) = @_;
    my $host = $self->{hosts}{$label};
    my $state = $host->{state};
    $state =~ /^(?:waiting|suspended|done|connecting)$/
	or die "internal error: disconnecting $label in state $state";
    if ($host->{ssh}) {
	$debug and _debug(connect => "[$label] disconnecting host");
	my $master_pid = delete $host->{master_pid};
	delete $self->{ssh_master_by_pid}{$master_pid}
	    if defined $master_pid;
	undef $host->{ssh};
	$self->{num_conns}--;
	$self->_set_host_state($label, $state);
    }
}

sub _disconnect_any_host {
    my $self = shift;
    my $connected = $self->{connected};
    $debug and _debug(conns => "disconnect any host");
    # $self->_audit_conns;
    my $label;
    for my $state (qw(suspended join_failed waiting)) {
	# use Data::Dumper;
	# print Dumper $connected;
	$debug and _debug(conns => "looking for connected host in state $state");
	($label) = each %{$connected->{$state}};
	keys %{$connected->{$state}}; # reset iterator
	last if defined $label;
    }
    $debug and _debug(conns => "[$label] disconnecting");
    defined $label or die "internal error: unable to disconnect any host";
    $self->_disconnect_host($label);
}

my @private_opts = qw(on_error or_goto reconnections);

sub _at_ready {
    my ($self, $label) = @_;
    if (my $max_workers = $self->{max_workers}) {
	my $in_state = $self->{in_state};
	my $num_workers = $self->_num_workers;
	$debug and _debug(workers => "num workers: $num_workers, maximum: $max_workers");
	if ($num_workers > $max_workers) {
	    $debug and _debug(workers => "[$label] suspending");
	    $self->_set_host_state($label, 'suspended');
	    return;
	}
    }

    my $host = $self->{hosts}{$label};
    $debug and _debug(at => "[$label] at_ready");

    my $queue = $host->{queue};

    if ($self->{abort_all}) {
        $self->_at_error($label, OSSH_ABORTED);
        return;
    }

    while (defined (my $task = shift @$queue)) {
	my $action = shift @$task;
	$debug and _debug(at => "[$label] at_ready, starting new action $action");
	if ($action eq 'join') {
	    my (undef, $join) = @$task;
	    if ($join->{done}) {
		$debug and _debug(join => "join[$join->{id}] is done");
		if ($join->{failed}) {
		    $self->_at_error($label, OSSH_JOIN_FAILED);
		    return;
		}
		$debug and _debug(action => "[$label] join $join->{id} already done");
		next;
	    }
	    CORE::push @{$join->{notify}}, $label;
	    $self->_set_host_state($label, 'waiting');
	    return;
	}
        elsif ($action eq 'here') {
            next;
        }
        elsif ($action eq 'stop') {
            $self->_skip($label, 'END');
            next;
        }
        elsif ($action eq 'goto') {
            my (undef, $target) = @$task;
            $self->_skip($label, $target);
            next;
        }
	elsif ($action eq '_notify') {
	    my (undef, $join) = @$task;
	    $self->_join_notify($label, $join);
	    next;
	}
	elsif ($action eq 'sub') {
            # use Data::Dumper;
            # _debug (action => Dumper(@$task));
	    shift @$task;
	    my $sub = shift @$task;
	    $debug and _debug(action => "[$label] calling sub $sub");
	    $sub->($self, $label, @$task);
	    next;
	}
	else {
            my $ssh = $host->{ssh};
            unless ($action eq 'parsub' and $task->[0]{no_ssh}) {
                unless ($ssh) {
                    # unshift the task we have just removed and connect first:
                    unshift @$task, $action;
                    unshift @$queue, $task;
                    if (my $max_conns = $self->{max_conns}) {
                        $self->_disconnect_any_host() if $self->{num_conns} >= $max_conns;
                    }
                    $debug and _debug(at => "[$label] host is not connected, connecting...");
                    $self->_at_connect($label);
                    return;
                }

                if (my $error = $ssh->error) {
                    $self->_at_error($label, $error);
                    return;
                }
            }

            next if $action eq 'connect';

            $host->{current_task} = [$action, @$task];
            my %opts = %{shift @$task};
            delete @opts{@private_opts};
            my $method = $self->can("_start_$action")
                or die "internal error: method _start_$action not found";
            my $pid = $method->($self, $label, \%opts, @$task);
            $debug and _debug(action => "[$label] action pid: ", $pid);
            unless (defined $pid) {
                my $error = (($ssh && $ssh->error) ||
                             dualvar(($action eq 'parsub'
                                      ? "Unable to fork parsub"
                                      : "Action $action failed to start"), OSSH_SLAVE_FAILED));
                $self->_at_error($label, $error);
                return;
            }
            $self->{host_by_pid}{$pid} = $label;
            $self->_set_host_state($label, 'running');
            return;
        }
    }
    $debug and _debug(at => "[$label] at_ready, queue_is_empty, we are done!");
    $self->_set_host_state($label, 'done');
    $self->_disconnect_host($label);
}

sub _start_parsub {
    my $self = shift;
    my $label = shift;
    my $opts = shift;
    my $sub = shift;
    my $ssh = $self->{hosts}{$label}{ssh};
    $debug and _debug(action => "[$label] start parsub action [@_]");
    my $pid = fork;
    unless ($pid) {
        defined $pid or return;
        eval { $sub->($label, $ssh, @_) };
        $@ and $debug and _debug(error => "slave died on parsub: $@");
        POSIX::_exit($@ ? 1 : 0);
    }
    $pid;
}

sub _start_command {
    my $self = shift;
    my $label = shift;
    my $opts = shift;
    my $ssh = $self->{hosts}{$label}{ssh};
    $debug and _debug(action => "[$label] start command action [@_]");
    $ssh->spawn($opts, @_);
}

sub _start_scp_get {
    my $self = shift;
    my $label = shift;
    my $opts = shift;
    my $ssh = $self->{hosts}{$label}{ssh};
    $debug and _debug(action => "[$label] start scp_get action");
    $opts->{async} = 1;
    $ssh->scp_get($opts, @_);
}

sub _start_scp_put {
    my $self = shift;
    my $label = shift;
    my $opts = shift;
    my $ssh = $self->{hosts}{$label}{ssh};
    $debug and _debug(action => "[$label] start scp_put action");
    $opts->{async} = 1;
    $ssh->scp_put($opts, @_);
}

sub _start_rsync_get {
    my $self = shift;
    my $label = shift;
    my $opts = shift;
    my $ssh = $self->{hosts}{$label}{ssh};
    $debug and _debug(action => "[$label] start rsync_get action");
    $opts->{async} = 1;
    $ssh->rsync_get($opts, @_);
}

sub _start_rsync_put {
    my $self = shift;
    my $label = shift;
    my $opts = shift;
    my $ssh = $self->{hosts}{$label}{ssh};
    $debug and _debug(action => "[$label] start rsync_put action");
    $opts->{async} = 1;
    $ssh->rsync_put($opts, @_);
}

# FIXME: dead code?
sub _start_join {
    my $self = shift;
    my $label = shift;
    warn "internal mismatch: this shouldn't be happening!";
}

sub _skip {
    my ($self, $label, $target) = @_;
    $debug and _debug(action => "skipping until $target");
    my $host = $self->{hosts}{$label};
    my $queue = $host->{queue};
    my ($ix, $task);
    for ($ix = 0; defined($task = $queue->[$ix]); $ix++) {
        last if ($task->[0] eq 'here' and $task->[2] eq $target);
    }
    if ($task or $target eq 'END') {
        for (1..$ix) {
            my $task = shift @$queue;
            $self->_join_notify($label, $task->[2])
                if $task->[0] eq '_notify';
        }
        return;
    }
    $debug and _debug(action => "here label $target not found");
    $self->_at_error($label, OSSH_GOTO_FAILED);
}

sub _finish_task {
    my ($self, $pid) = @_;
    my $label = delete $self->{host_by_pid}{$pid};

    if (defined $label) {
	$debug and _debug(action => "[$label] action finished pid: $pid, rc: $?");
	my $host = $self->{hosts}{$label};
        my $or_goto;
        if ($?) {
            my ($action) = @{$host->{current_task}};
            my $rc = ($? >> 8);
            my $ssh = $host->{ssh} or die "internal error: $label is not connected";
            my $error = $ssh->error;
            $or_goto = $host->{current_task}[1]{or_goto} unless ($error or $rc == 255);
            if (defined $or_goto) {
                $debug and _debug(action => "[$label] skipping to $or_goto with rc = $rc");
            }
            else {
                $error ||= dualvar(OSSH_SLAVE_FAILED,
                                   "child exited with non-zero return code ($rc)");
                $self->_at_error($label, $error);
                return
            }
        }
        $self->_set_host_state($label, 'ready');
        $self->_skip($label, $or_goto) if defined $or_goto;
        delete $host->{current_task};
        delete $host->{current_task_reconnections};
    }
    else {
	my $label = delete $self->{ssh_master_by_pid}{$pid};
	defined $label or carp "spurious child exit (pid: $pid)";

        $debug and _debug(action => "[$label] master ssh exited");
        my $host = $self->{hosts}{$label};
        my $ssh = $host->{ssh}
            or die ("internal error: master ssh process exited but ".
                    "there is no ssh object associated to host $label");
        $ssh->master_exited;
        my $state = $host->{state};
        # do error handler later...
    }
}

sub _wait_for_jobs {
    my ($self, $time) = @_;
    my $dontwait = ($time == 0);
    $debug and _debug(at => "_wait_for_jobs time: $time");
    # This loop is here because we want to call waitpit before and
    # after the select. If we find some child has exited in the first
    # round we don't call select at all and return immediately
    while (1) {
	if (%{$self->{in_state}{running}}) {
	    $debug and _debug(at => "_wait_for_jobs reaping children");
	    while (1) {
		my $pid = waitpid(-1, WNOHANG);
		last if $pid <= 0;
		$debug and _debug(action => "waitpid caught pid: $pid, rc: $?");
		$dontwait = 1;
		$self->_finish_task($pid);
	    }
	}
	$dontwait and return 1;
	$debug and _debug(at => "_wait_for_jobs calling select");
	{
	    # This is a hack to make select finish as soon as we get a
	    # CHLD signal.
	    local $SIG{CHLD} = sub {};
	    select(undef, undef, undef, $time);
	}
	$dontwait = 1;
    }
}

sub _clean_errors {
    my $self = shift;
    delete $_->{error} for values %{$self->{hosts}};
}

sub run {
    my ($self, $time) = @_;

    $self->_clean_errors;

    my $hosts = $self->{hosts};
    my $max_workers = $self->{max_workers};
    my ($connecting, $ready, $running, $waiting, $suspended, $join_failed, $done) =
	@{$self->{in_state}}{qw(connecting ready running waiting suspended join_failed done)};
    my $connected_suspended = $self->{connected}{suspended};
    while (1) {
	# use Data::Dumper;
	# print STDERR Dumper $self;
	$debug and _debug(api => "run: iterating...");

	$debug and _debug(at => "run: hosts at connecting: ", scalar(keys %$connecting));
	$self->_at_connecting($_) for keys %$connecting;

	$debug and _debug(at => "run: hosts at ready: ", scalar(keys %$ready));

	# $self->_audit_conns;
	$self->_at_ready($_) for keys %$ready;
	# $self->_audit_conns;

	$debug and _debug(at => 'run: hosts at join_failed: ', scalar(keys %$join_failed));
	$self->_at_error($_, OSSH_JOIN_FAILED) for keys %$join_failed;

	if ($max_workers) {
	    $debug and _debug(at => "run: hosts at suspended:", scalar(keys %$suspended));
	    if (%$suspended) {
		my $awake = $max_workers - $self->_num_workers;
		my @labels;
		for my $hash ($connected_suspended, $suspended) {
		    while ($awake > 0) {
			my ($label) = each %$hash or last;
			CORE::push @labels, $label;
			$awake--;
		    }
		    for my $label (@labels) {
			$debug and _debug(workers => "[$label] awaking");
			$self->_set_host_state($label, 'ready');
		    }
		    keys %$hash; # do we really need to reset the each iterator?
		}
	    }
	}

	$debug and _debug(at => "run: hosts at waiting: ", scalar(keys %$waiting));
	$debug and _debug(at => "run: hosts at running: ", scalar(keys %$running));
	$debug and _debug(at => "run: hosts at done: ", scalar(keys %$done), " of ", scalar(keys %$hosts));

	last if keys(%$hosts) == keys(%$done);

	my $time = ( %$ready      ? 0   :
		     %$connecting ? 0.3 :
		                    5.0 );
	$self->_wait_for_jobs($time);
    }

    delete $self->{abort_all};

    my $error;
    for my $label (sort keys %$hosts) {
	$hosts->{$label}{error} and $error = 1;
	$debug and _debug(error => "[$label] error: ", $hosts->{$label}{error});
    }
    !$error;
}

sub get_error {
    my ($self, $label) = @_;
    my $host = $self->{hosts}{$label}
	or croak "no such host $label has been added";
    $host->{error}
}

sub get_errors {
    my $self = shift;
    if (wantarray) {
        return map {
            my $error = $self->get_error($_);
            defined $error ? ($_ => $error) : ()
        } sort keys %{$self->{hosts}}
    }
    else {
        return grep defined($self->get_error($_)), keys %{$self->{hosts}}
    }
}

1;

__END__

=head1 NAME

Net::OpenSSH::Parallel - Run SSH jobs in parallel

=head1 SYNOPSIS

  use Net::OpenSSH::Parallel;

  my $pssh = Net::OpenSSH::Parallel->new();
  $pssh->add_host($_) for @hosts;

  $pssh->push('*', scp_put => '/local/file/path', '/remote/file/path');
  $pssh->push('*', command => 'gurummm',
              '/remote/file/path', '/tmp/output');
  $pssh->push($special_host, command => 'prumprum', '/tmp/output');
  $pssh->push('*', scp_get => '/tmp/output', 'logs/%HOST%/output');

  $pssh->run;

=head1 DESCRIPTION

Run this here, that there, etc.

C<Net::OpenSSH::Parallel> is an scheduler that can run commands in
parallel in a set of hosts through SSH. It tries to find a compromise
between being simple to use, efficient and covering a good part of the
problem space of parallel process execution via SSH.

Obviously, it is build on top of L<Net::OpenSSH>!

Common usage of the module is as follows:

=over

=item *

create a C<Net::OpenSSH::Parallel> object

=item *

register the hosts where you want to run commands with the
L</add_host> method

=item *

queue the actions you want to run (commands, file copy operations,
etc.) using the L</push> method.

=item *

call the L</run> method and let the parallel scheduler take care of
everything!

=back

=head2 Labeling hosts

Every host is identified by an unique label that is given when the
host is registered into the parallel scheduler. Usually, the host
name is used also as the label, but this is not required by the
module.

The rationale behind using labels is that a hostname does not
necessarily identify unique "remote processors" (for instance,
sometimes your logical "remote processors" may be user accounts
distributed over a set of hosts: C<foo1@bar1>, C<foo2@bar1>,
C<foo3@bar2>, ...; a set of hosts that are accessible behind an unique
IP, listening in different ports; etc.)

=head2 Selecting hosts

Several of the methods of this module (well, currently, just C<push>)
accept a selector string to determine which of the registered hosts
should be affected by the operation.

For instance, in...

  $pssh->push('*', command => 'ls')

the first argument is the selector. The one used here, C<*>, selects
all the registered hosts.

Other possible selectors are:

  'bar*'                # selects everything beginning by 'bar'
  'foo1,foo3,foo6'      # selects the hosts of the given names
  'bar*,foo1,foo3,foo6' # both
  '*doz*'               # everything containing 'doz'

I<Note: I am still considering how the selector mini-language should
be, do not hesitate to send your suggestions!>

=head2 Local resource usage

When the number of hosts managed by the scheduler is too high, the
local node can become overloaded.

Roughly, every SSH connection requires two local C<ssh> processes
(one to run the SSH connection and another one to launch the remote
command) that results in around 5MB of RAM usage per host.

CPU usage varies greatly depending on the tasks carried out. The most
expensive are short remote tasks (because of the local process
creation and destruction overhead) and tasks that transfer big
amounts of data through SSH (because of the encryption going on).

In practice, CPU usage does not matter too much (mostly because the OS
would be able to manage it but also because there is not too many
things we can do to reduce it) and usually it is RAM about what we
should be more concerned.

The module accepts two parameters to limit resource usage:

=over

=item * C<workers>

is the maximum number of remote commands that can be running
concurrently.

=item * C<connections>

is the maximum number of SSH connections that can be active
concurrently.

=back

In practice, limiting the maximum number of connections indirectly
limits RAM usage and limiting the the maximum number of workers
indirectly limits CPU usage.

The module requires the maximum number of connections to be at least
equal or bigger than the maximum number of workers, and it is
recommended that C<maximum_connections E<gt>= 2 * maximum_workers>
(otherwise the scheduler will not be able to reuse connections
efficiently).

You will have to experiment to find out which combinations give the
best results in your particular scenarios.

Also, for small sets of hosts you can just let these parameters
unlimited.

=head2 Variable expansion

This module activates L<Net::OpenSSH> L<variable
expansion|Net::OpenSSH/Variable expansion> by default. That way, it is
possible to easily customize the actions executed on every host in
base to some of its properties.

For instance:

  $pssh->push('*', scp_get => "/var/log/messages", "messages.%HOST%");

copies the log files appending the name of the remote hosts to the
local file names.

The variables C<HOST>, C<USER>, C<PORT> and C<LABEL> are predefined.

=head2 Error handling

When something goes wrong (for instance, some host is unreachable,
some connection dies, some command fails, etc.) the module can handle
the error in several predefined ways as follows:

=head3 Error policies

To set the error handling police, L</new>, L</add_host> and L</push>
methods support and optional C<on_error> argument that can take the
following values (these constants are available from
L<Net::OpenSSH::Parallel::Constants>):

=over 4

=item OSSH_ON_ERROR_IGNORE

Ignores the error and continues executing tasks in the host queue as
it had never happened.

=item OSSH_ON_ERROR_ABORT

Aborts the processing on the corresponding host. The error will be
propagated to other hosts joining it at any later point once the join
is reached.

In other words, this police aborts the queued jobs for this host
and any other that has a dependency on it.

=item OSSH_ON_ERROR_DONE

Similar to C<OSSH_ON_ERROR_ABORT> but will not propagate errors to
other hosts via joins.

=item OSSH_ON_ERROR_ABORT_ALL

Causes all the host queues to be aborted as soon as possible (and that
usually means after currently running actions end).

=item OSSH_ON_ERROR_REPEAT

The module will try to perform the current task again and again until
it succeeds. This police can lead to an infinite loop and so its
direct usage is discouraged (but see the following point about setting
the policy dynamically).

=back

The default policy is C<OSSH_ON_ERROR_ABORT>.

=head3 Setting the policy dynamically

When a subroutine reference is used as the policy instead of the any of the
constants previously described, the given subroutine will be called on
error conditions as follows:

  $on_error->($pssh, $label, $error, $task)

C<$pssh> is a reference to the C<Net::OpenSSH::Parallel> object,
C<$label> is the label associated to the host where the error
happened. C<$error> is the error type as defined in
L<Net::OpenSSH::Parallel::Constants> and $task is a reference to the
task that was being carried out.

The return value of the subroutine must be one of the described
constants and the corresponding policy will be applied.

=head3 Retrying connection errors

If the module fails when trying to establish a new SSH connection or
when an existing connection dies unexpectedly, the option
C<reconnections> can be used to instruct the module to retry the
connection until it succeeds or the given maximum is reached.

C<reconnections> is accepted by both the L</new> and L</add_host>
methods.

Example:

  $pssh->add_host('foo', reconnections => 3);

Note that the reconnections maximum is not per host but per queued
task.

=head2 API

These are the available methods:

=over

=item $pssh = Net::OpenSSH::Parallel->new(%opts)

creates a new object.

The accepted options are:

=over

=item workers => $maximum_workers

sets the maximum number of operations that can be carried out in
parallel (see L</Local resource usage>).

=item connections => $maximum_connections

sets the maximum number of SSH connections that can be established
simultaneously (see L</Local resource usage>).

$maximum_connections must be equal or bigger than $maximum_workers

=item reconnections => $maximum_reconnections

when connecting to some host fails, this argument tells the module the
maximum number of additional connection attempts that it should
perform before giving up. The default value is zero.

See also L</Retrying connection errors>.

=item on_error => $policy

Sets the error handling policy (see L</Error handling>).

=back

=item $pssh->add_host($label, %opts)

=item $pssh->add_host($label, $host, %opts)

X<add_host>registers a new host into the C<$pssh> object.

C<$label> is the name used to refer to the registered host afterwards.

When the hostname argument is omitted, the label is used also as the
hostname.

The accepted options are:

=over

=item on_error => $policy

Sets the error handling policy (see L</Error handling>).

=item reconnections => $maximum_reconnections

See L</Retrying connection errors>.

=back

Any additional option will be passed verbatim to the L<Net::OpenSSH>
constructor later. For instance:

  $pssh->add_host($host, user => $user, password => $password);


=item $pssh->push($selector, $action, \%opts, @action_args)

=item $pssh->push($selector, $action, @action_args)

pushes a new action into the queues selected by C<$selector>.

The supported actions are:

=over

=item command => @cmd

queue the given shell command on the selected hosts.

Example:

  $self->push('*', 'command'
              { stdout_fh => $find_fh, stderr_to_stdout => 1 },
              'find', '/my/dir');

=item scp_get => @remote, $local

=item scp_put => @local, $remote

These methods queue a C<scp> remote file copy operation in the selected
hosts.

=item rsync_get => @remote, $local

=item rsync_put => @local, $remote

These methods queue an rsync remote file copy operation in the
selected hosts.

=item sub => sub { ... }, @extra_args

=item sub { ... }, @extra_args

Queues a call to a perl subroutine that will be executed locally.

Note that subroutines are executed synchronously in the same process,
so no other task will be scheduled while they are running.

The sub is called as

  $sub->($pssh, $label, @extra_args)

where C<$pssh> is the current Net::OpenSSH::Parallel object.

=item parsub => sub { ... }, @extra_args

Queues a call to a perl subroutine that will be executed locally on a
forked process.

The sub is called as

  $sub->($label, $ssh, @extra_args)

Where C<$ssh> is an L<Net::OpenSSH> object that can be used to
interact with the remote machine.

Note that the interface is different to that of the C<sub> action.

An example of usage:

  sub sudo_install {
      my ($label, $ssh, @pkgs) = @_;
      my ($pty) = $ssh->open2pty('sudo', 'apt-get', 'install', @pkgs);
      my $expect = Expect->init($pty);
      $expect->raw_pty(1);
      $expect->expect($timeout, ":");
      $expect->send("$passwd\n");
      $expect->expect($timeout, "\n");
      $expect->raw_pty(0);
      while(<$expect>) { print };
      close $expect;
  }

  $pssh->push('*', parsub => \&sudo_install, 'scummvm');

If the subroutine dies or calls C<_exit> with a non zero return code,
the error handling code will be triggered (see L</"Error handling">).

The C<parsub> action accepts the additional option C<no_ssh>
indicating that the C<$ssh> object is not going to be used. For
instance:

  $pssh->push('*', parsub => { no_ssh => 1 },
              sub {
                    my $label = shift;
                    { exec "gzip", "/tmp/file-$label" };
                    die "exec failed: $!";
              });

That can make the script faster when the maximum number of
simultaneous connections is limited. See L<Local resource usage>.

=item join => $selector

Joins allow to synchronize jobs between different servers.

For instance:

  $ssh->push('server_B', scp_get => '/tmp/foo', 'foo');
  $ssh->push('server_A', join => 'server_B');
  $ssh->push('server_A', scp_put => 'foo', '/tmp/foo');

The join makes server_A to wait for the C<scp_get> operation queued in
server_B to finish before proceeding with the C<scp_put>.

In general the join will make the selected servers wait for any task
queued on the servers matched by C<$selector> to finish before
proceeding with the next queued tasks.

One common usage is to synchronize all servers at some point:

  $ssh->push('*', join => '*');

By default, errors are propagated at joins. For instance, in the
example above, if the C<scp_get> operation queued on server_B failed, it
would abort any further operation queued on server_B and any further
operation queued after the join in server_A. See also L</Error
handling>.

=item here => $tag

Push a tag in the stack that can be used as a target for goto
operations.

=item goto => $target

Jumps forward until the given C<here> tag is reached.

Joins to other hosts queues will be ignored, and joins from other
queues to this one will be successfully fulfilled. For instance:

  $pssh->add_host(A => ...);
  $pssh->add_host(B => ...);
  $pssh->push('*', cmd  => 'echo "hello from %HOST"');
  $pssh->push('A', goto => 'there');
  $pssh->push('A', join => 'B');                     # ignored by A on goto
  $pssh->push('B', join => 'A');                     # fulfilled by A on goto
  $pssh->push('*', cmd  => 'echo "hello from %HOST% again"');
  $pssh->push('*', here => 'there');
  $pssh->push('*', cmd  => 'echo "bye bye from %HOST%");

Note that it is not possible to jump backwards.

There is an special target C<END> that can be used to jump to the end
of the queue.

=item stop

Discards any additional operations queued. Any pending joins will be
successfully fulfilled.

It is equivalent to

  $pssh->push('*', goto => 'END');

=item connect

Just ensures that connecting to the remote machine is possible without
doing any other action.

=back

When given, C<%opts> can contain the following options:

=over 4

=item on_error => $fail_mode

=item on_error => sub { ... }

See L</Error handling>.

=item or_goto => $tag

Supported for C<command>, C<scp_get>, C<scp_put>, C<rsync_get> and
C<rsync_put>, when the command, C<scp> or C<rsync> operation fails a
C<goto> to the given target is performed.

For instance:

  $pssh->all(command => { or_goto => 'no_file' },
                        "test -f /etc/foo");
  $pssh->all(scp_get => "/etc/foo", "/tmp/foo-%LABEL%");
  $pssh->all(here    => "no_file");

Failures related to SSH errors do not trigger the goto but the error
handling code.

=item timeout => $seconds

not implemented yet!

=item on_done => sub { ... }

not implemented yet!

=back

Any other option will be passed to the corresponding L<Net::OpenSSH>
method (L<spawn|Net::OpenSSH/spawn>, L<scp_put|Net::OpenSSH/scp_put>,
etc.).

=item $pssh->all($action => @args)

=item $pssh->all($action => \%opts, @args)

Shortcut for...

  $pssh->push('*', $action, \%opts, @args);

=item $pssh->run

Runs the queued operations.

It returns a true value on success and false otherwise.

=item $pssh->get_error($label)

Returns the last error associated to the host of the given label.

=item $pssh->get_errors

In list context returns a list of pairs C<$label =E<gt> $error> for the failed queues.

In scalar context returns the number of failed queues.

=back

=head1 FAQ - Frequently Asked Questions

=over 4

=item Running remote commands with sudo

B<Q>: I need to run the remote commands with sudo that asks for a
password. How can I do it?

B<A>: First read the answer given to a similar question on
L<Net::OpenSSH> FAQ.

The problem is that Net::OpenSSH::Parallel methods do not support the
<stdin_data> option, so you will have to use an external file.

  $pssh->push('*', cmd => { stdin_file => $passwd_file },
                   'sudo', '-Skp', '', '--', @cmd);

One trick you can use if you only have one password is to use the
C<DATA> file handle:

  $pssh->push('*', cmd => { stdin_fh => \*DATA},
              'sudo', '-Skp', '', '--', @cmd);
  ...
  # and at the end of your script
  __DATA__
  this-is-my-remote-password-for-sudo

Or you can also use the C<parsub> action:

  my %sudo_passwords = (host1 => "foo", ...);

  sub sudo {
    my ($label, $ssh, @cmd) = @_;
    $ssh->system({stdin_data => "$sudo_passwords{$label}\n"},
                 'sudo', '-Skp', '', '--', @cmd);
  }

  $pssh->push('*', parsub => \&sudo, @cmd);


=back

=head1 TODO

=over

=item * run N processes per host concurrently

allow running more than one process per remote server concurrently

=item * delay before reconnect

when connecting fails, do not try to reconnect immediately but after
some predefined period

=item * rationalize debugging

currently it is a mess

=item * add logging support

log the operations performed in a given file

=item * stdio redirection

add support for better handling of the Net::OpenSSH stdio redirection
facilities

=item * configurable valid return codes

Non zero exit code is not always an error.

=back

=head1 BUGS AND SUPPORT

This module should be considered beta quality, everything seems to
work but it may yet contain critical bugs.

If you find any, report it via L<http://rt.cpan.org> or by email (to
sfandino@yahoo.com), please.

Feedback and comments are also welcome!

The 'sub' and 'parsub' features should be considered experimental and
its API or behavior could be changed in future versions of the
module.

=head2 Reporting bugs

In order to report a bug, write a minimal program that triggers
it and place the following line at the beginning:

  $Net::OpenSSH::Parallel::debug = -1;

Then, send me (via RT or email) the debugging output you get when you
run it. Include also the source code of the script, a description of
what is going wrong and the details of your OS and the versions of
Perl, C<Net::OpenSSH> and C<Net::OpenSSH::Parallel> you are using.

=head2 Development version

The source code for this module is hosted at GitHub:
L<http://github.com/salva/p5-Net-OpenSSH-Parallel>.

=head2 Commercial support

Commercial support, professional services and custom software
development around this module are available through my current
company. Drop me an email with a rough description of your
requirements and we will get back to you ASAP.

=head2 My wishlist

If you like this module and you are feeling generous, take a look at
my Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>

Also consider contributing to the OpenSSH project this module builds
upon: L<http://www.openssh.org/donations.html>.

=head1 SEE ALSO

L<Net::OpenSSH> is used to manage the SSH connections to the remote
hosts.

L<SSH::Batch> has a similar focus as this module. In my opinion it is
simpler to use but rather more limited.

L<GRID::Machine> allows to run perl code distributed in a cluster via
SSH.

If your application requires orchestrating work-flows more complex than
those supported by L<Net::OpenSSH::Parallel>, you should probably
consider some L<POE> or L<AnyEvent> based solution (check
L<POE::Component::OpenSSH>).

L<App::MrShell> is another module allowing to run the same command in
several host in parallel.

Some people find easier to use L<Net::OpenSSH> combined with
L<Parallel::ForkManager>, L<threads> or L<Coro>.

L<Net::SSH::Mechanize> is another framework written on top of
L<AnyEvent> that allows to run remote commands through SSH in
parallel.

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2009-2012, 2015 by Salvador FandiE<ntilde>o
(sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
