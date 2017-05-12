package MojoX::Run;

use strict;
use warnings;

use base 'Mojo::Base';

use bytes;
use Time::HiRes qw(time);
use POSIX qw(:sys_wait_h);
use Scalar::Util qw(blessed);

use Storable qw(thaw freeze);

use Mojo::Log;
use Mojo::IOLoop;

use MojoX::_Open3;
use MojoX::HandleRun;

# timeout in seconds (~10 years)
use constant VERY_LONG_TIMEOUT => 60 * 60 * 24 * 365 * 10;

# private logging object...
my $_log = Mojo::Log->new();

# singleton object instance
my $_obj = undef;

our $VERSION = '0.15';

=head1 NAME

MojoX::Run - asynchronous external command and subroutine execution for Mojo

=head1 SYNOPSIS

 # create async executor SINGLETON object
 my $mojox_run = MojoX::Run->singleton();
 
 # simple usage
 my $pid = $mojox_run->spawn(
 	cmd => "ping -W 2 -c 5 host.example.org",
 	exit_cb => sub {
 		my ($pid, $res) = @_;
 		print "Ping finished with exit status $res->{exit_val}.\n";
 		print "\tSTDOUT:\n$res->{stdout}\n";
 		print "\tSTDERR:\n$res->{stderr}\n";
 	}
 );
 # check for injuries
 unless ($pid) {
 	print "Command startup failed: ", $mojox_run->error(), "\n";
 }
 
 # more complex example...
 my $pid2 = $mojox_run->spawn(
 	cmd => 'ping -W 2 -c 5 host.example.org',
 	stdin_cb => sub {
 		my ($pid, $chunk) = @_;
 		print "STDOUT $pid: '$chunk'\n"
 	},
 	# ignore stderr
 	stderr_cb => sub {},
 	exit_cb => sub {
 		my ($pid, $res) = @_;
 		print "Process $res->{cmd} [pid: $pid] finished after $res->{time_duration_exec} second(s).\n";
 		print "Exit status: $res->{exit_status}";
 		print " by signal $res->{exit_signal}" if ($res->{exit_signal});
 		print " with coredump." if ($res->{exit_core});
 		print "\n";
 	}
 );
 
 # even fancier usage: spawn coderef
 my $pid3 = $mojox_run->spawn(
 	cmd => sub {
 		for (my $i = 0; $i < 10; $i++) {
 			if (rand() > 0.5) {
 				print STDERR rand(), "\n"
 			} else {
 				print rand(), "\n";
 			}
 			sleep int(rand(10));
 		}
 		exit (rand() > 0.5) ? 0 : 1;
 	},
 	exit_cb => {
 		print "Sub exited with $res->{exit_status}, STDOUT: $res->{stdout}\n";
 	},
 );

=head1 SIGCHLD WARNING

Object instance of this class takes over B<SIGCHLD> signal handler. You have been
warned!

=head1 OBJECT CONSTRUCTOR

=head2 new

Alias for L</singleton> method - object constructor always returns the same
object instance.

This restriction is enforced becouse there can be only one active B<SIGCHLD>
signal handler per process. However this shouldn't be a problem becouse
you can run multiple external processes simultaneously with MojoX::Run :)

=cut
sub new {
	return __PACKAGE__->singleton();
}

=head2 singleton

 my $mojox_run = MojoX::Run->singleton();

Returns singleton object instance of MojoX::Run. Singleton object uses Mojo's
L<Mojo::IOLoop> singleton instance. This is probably what you want instead of
creating your own private instance.

=cut
sub singleton {
	# return existing instance if available
	return $_obj if (defined $_obj);
	
	# no singleton object? create one
	$_obj = __PACKAGE__->_constructor();
	return $_obj;
}

# the real constructor
sub _constructor {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();

	bless($self, $class);
	$self->_init();
	
	# do we have any arguments?
	# argument can only be ioloop object...
	$self->ioloop(@_) if (@_);
	
	return $self;
}

sub DESTROY {
	my ($self) = @_;
	
	# perform cleanup...
	foreach my $pid (keys %{$self->{_data}}) {
		my $proc = $self->{_data}->{$pid};

		# kill process (HARD!)
		kill(9, $pid);
		$_log->debug("Killing subprocess $pid with SIGKILL") if (defined $_log);

		my $loop = $self->ioloop();
		next unless (defined $loop);

		# drop fds
		if (defined $proc->{id_stdout}) {
			$loop->drop($proc->{id_stdout});
		}
		if (defined $proc->{id_stderr}) {
			$loop->drop($proc->{id_stderr});
		}
		if (defined $proc->{id_stdin}) {
			$loop->drop($proc->{id_stdin});
		}

		# fire exit callbacks (if any)
		$self->_checkIfComplete($pid, 1);

		# remove struct
		delete($self->{_data}->{$pid});
	}

	# disable sigchld hander
	$SIG{'CHLD'} = 'IGNORE';
}

##################################################
#                PUBLIC METHODS                  #
##################################################

=head1 METHODS

=head2 error

 my $err = $mojox_run->error();

Returns last error.

=cut

sub error {
	my ($self) = @_;
	return $self->{_error};
}

=head2 spawn

 my $pid = $mojox_run->spawn(%opt);

Spawns new subprocess. The following options are supported:

=over

=item B<cmd> (string/arrayref/coderef, undef, B<required>):

Command to be started. Command can be simple scalar, array reference or perl CODE reference
if you want to custom perl subroutine asynchronously.

=item B<stdout_cb> (coderef, undef):

Code that will be invoked when data were read from processes's stdout. If omitted, stdout output
will be returned as argument to B<exit_cb>. Example:

 stdout_cb => sub {
 	my ($pid, $data) = @_;
 	print "Process $pid stdout: $data";
 }

=item B<stderr_cb> (coderef, undef):

Code that will be invoked when data were read from processes's stderr. If omitted, stderr output
will be returned as argument to B<exit_cb>. Example:

 stderr_cb => sub {
 	my ($pid, $data) = @_;
 	print "Process $pid stderr: $data";
 }

=item B<stdin_cb> (coderef, undef):

Code that will be invoked when data wrote to process's stdin were flushed. Example:

 stdin_cb => sub {
 	my ($pid) = @_;
 	print "Process $pid: stdin was flushed.";
 }

=item B<exit_cb> (coderef, undef, B<required>)

Code to be invoked after process exits and all handles have been flushed. Function is called
with 2 arguments: Process identifier (pid) and result structure. Example:

 exit_cb => sub {
 	my ($pid, $res) = @_;
 	print "Process $pid exited\n";
 	print "Execution error: $res->{error}\n" if (defined $res->{error});
 	print "Exit status: $pid->{exit_status}\n";
 	print "Killed by signal $pid->{exit_signal}\n" if ($res->{exit_signal});
 	print "Process dumped core.\n" if (res->{exit_core});
 	print "Process was started at: $res->{time_started}\n";
 	print "Process exited at $res->{time_stopped}\n";
 	print "Process execution duration: $res->{time_duration_exec}\n";
 	print "Execution duration: $res->{time_duration_total}\n";
 	print "Process stdout: $res->{stdout}\n";
 	print "Process stderr: $res->{stderr}\n";
 }

=item B<exec_timeout> (float, 0):

If set to positive non-zero value, process will be killed after specified timeout of seconds. Timeout accuracy
depends on IOLoop's timeout() value (Default is 0.25 seconds).

=back

Returns non-zero process identifier (pid) on success, otherwise 0 and sets error.

=cut

sub spawn {
	my ($self, %opt) = @_;
	unless (defined $self && blessed($self) && $self->isa(__PACKAGE__)) {
		my $obj = __PACKAGE__->new();
		return $obj->spawn(%opt);
	}
	$self->{_error} = '';

	# normalize and validate run parameters...
	my $o = $self->_getRunStruct(\%opt);
	return 0 unless ($self->_validateRunStruct($o));

	# start exec!
	return $self->_spawn($o);
}

=head2 spawn_sub

 my $code = sub { return { a => 1, b => 2} };
 my $pid = $mojox_run->spawn_sub(
 	$code,
 	exit_cb => sub {
 		my ($pid, $result, $exception) = @_;
 	}
 );

Spawns new subprocess in which $code subroutine will be executed. Return value of
subroutine will be delivered to B<exit_cb> callback.

The following options are supported:

=over

=item B<stdin_cb> (coderef, undef):

Code that will be invoked when data wrote to process's stdin were flushed. Example:

 stdin_cb => sub {
 	my ($pid) = @_;
 	print "Process $pid: stdin was flushed.";
 }

=item B<exit_cb> (coderef, undef, B<required>)

Code to be invoked after process exits and all handles have been flushed. Function is called
with 2 arguments: Process identifier (pid) and result structure. Example:

 exit_cb => sub {
 	my ($pid, $result, $exception) = @_;
 	if ($exception) {
 		print "Horrible exception accoured while executing subroutine: $exception";
 		return;
 	}
 	
 	# result is always arrayref, becouse subs can return list values!
 	print "Got async sub result: ", Dumper($result), "\n";
 }

=item B<exec_timeout> (float, 0):

If set to positive non-zero value, process will be killed after specified timeout of seconds. Timeout accuracy
depends on IOLoop's timeout() value.

=back

Returns non-zero process identifier (pid) on success, otherwise 0 and sets error.

=cut
sub spawn_sub {
	my ($self, $sub, %opt) = @_;
	unless (defined $sub && ref($sub) eq 'CODE') {
		$self->{_error} = "First argument must be coderef.";
		return 0;
	}
	my $exit_cb = delete($opt{exit_cb});
	unless (defined $exit_cb && ref($exit_cb)) {
		$self->{_error} = "No exit_cb defined!";
		return 0;
	}
	
	# remove stupid stuff from %opt
	delete($opt{stdout_cb});
	delete($opt{stderr_cb});
	
	# wrap sub to our custom routine
	my $code = sub {
		# run sub...
		local $@;
		my @rv = eval { $sub->() };
		
		# exception?
		if ($@) {
			print STDERR "Exception: $@";
			CORE::exit(1);
		}
		
		# we have a result!
		print freeze(\ @rv);
		CORE::exit(0);
	};
	
	# wrap exit_cb to our routine
	my $exit_code = sub {
		my ($pid, $res) = @_;
		my $ref = undef;
		my $ex = undef;
		# everything ok?
		if ($res->{exit_status} == 0) {
			local $@;
			# try to de-serialize data...
			$ref = eval { thaw($res->{stdout}) };
			# check for injuries...
			if ($@) {
				$ex = "Error de-serializing subprocess data: $@";
			}
		} else {
			$ex = $res->{stderr};
		}
		
		# run exit cb...
		$exit_cb->($pid, $ref, $ex);
	};
	
	# spawn the goddamn sub
	my $p = $self->spawn(
		cmd => $code,
		%opt,
		exit_cb => $exit_code,
	);
	
	return 0 unless ($p);

	# lock down stdout/err streams...
	$self->_lock_output($p);
	
	return $p;
}

=head2 stdin_write

 $mojox_run->stdin_write($pid, $data [, $cb]);

Writes $data to stdin of process $pid if process still has opened stdin. If $cb is defined
code reference it will invoke it when data has been written. If $cb is omitted B<stdin_cb>
will be invoked if is set for process $pid.

Returns 1 on success, otherwise 0 and sets error.

=cut

sub stdin_write {
	my ($self, $pid, $data, $cb) = @_;
	my $proc = $self->_getProcStruct($pid);
	unless (defined $pid && defined $proc) {
		$self->{_error} =
		  "Unable to write to process pid '$pid' stdin: Unamanaged process pid or process stdin is already closed.";
		return 0;
	}

	# is stdin still opened?
	unless (defined $proc->{id_stdin}) {
		$self->{_error} = "STDIN handle is already closed.";
		return 0;
	}

	# do we have custom callback?
	if (defined $cb) {
		unless (ref($cb) eq 'CODE') {
			$self->{_error} =
			  "Optional second argument must be code reference.";
			return 0;
		}
	}
	else {

		# do we have stdin callback?
		if (defined $proc->{stdin_cb} && ref($proc->{stdin_cb}) eq 'CODE') {
			$cb = $proc->{stdin_cb};
		}
	}

	# write data
	$self->ioloop()->write($proc->{id_stdin}, $data, $cb);
	return 1;
}

=head2 stdout_cb

 # set
 $mojox_run->stdout_cb($pid, $cb);
 # get
 my $cb = $mojox_run->stdout_cb($pid);

If called without $cb argument returns stdout callback for process $pid, otherwise
sets stdout callback. If $cb is undefined, removes callback.

Returns undef on error and sets error message.

=cut

sub stdout_cb {
	my ($self, $pid, $cb) = @_;
	return $self->__handle_cb($pid, 'stdout', $cb);
}

=head2 stderr_cb

 # set
 $mojox_run->stderr_cb($pid, $cb);
 # get
 $cb = $mojox_run->stderr_cb($pid);

If called without $cb argument returns stderr callback for process $pid, otherwise
sets stderr callback. If $cb is undefined, removes callback.

Returns undef on error and sets error message.

=cut

sub stderr_cb {
	my ($self, $pid, $cb) = @_;
	return $self->__handle_cb($pid, 'stderr', $cb);
}

=head2 stdin_cb

 # set
 $mojox_run->stdin_cb($pid, $cb);
 # get
 $mojox_run->stdin_cb($pid);

If called without $cb argument returns stdin callback for process $pid, otherwise
sets stdin callback. If $cb is undefined, removes callback.

Returns undef on error and sets error message.

=cut

sub stdin_cb {
	my ($self, $pid, $cb) = @_;
	return $self->__handle_cb($pid, 'stdin', $cb);
}

=head2 stdin_close

 $mojox_run->stdin_close($pid);

Closes stdin handle to specified process. You need to explicitly close stdin
if spawned program doesn't exit until it's stdin is not closed.

=cut

sub stdin_close {
	my ($self, $pid) = @_;
	my $proc = $self->_getProcStruct($pid);
	return 0 unless (defined $proc);

	# is stdin opened?
	my $id_stdin = $proc->{id_stdin};
	unless (defined $id_stdin) {
		$self->{_error} = "STDIN is already closed.";
		return 0;
	}

	my $loop = $self->ioloop();
	unless (defined $loop) {
		$self->{_error} = "Undefined IOLoop.";
		return 0;
	}

	# drop handle...
	$loop->drop($id_stdin);
	$proc->{id_stdin} = undef;

	return 1;
}

=head2 stdout_buf

 # just get it
 $buf = $mojox_run->stdout_buf($pid);
 # get and drain
 $buf = $mojox_run->stdout_buf($pid, 1);

Returns contents of stdout buffer for process $pid on success, otherwise undef.

Internal buffer is cleared if invoked with non-zero second argument.

=cut

sub stdout_buf {
	my ($self, $pid, $clear) = @_;
	$clear = 0 unless (defined $clear);
	my $proc = $self->_getProcStruct($pid);
	return undef unless (defined $proc);
	return undef if ($proc->{out_locked});

	# clear buffer?
	$proc->{buf_stdout} = '' if ($clear);
	return $proc->{buf_stdout};
}

=head2 stdout_buf_clear

 $buf = $mojox_run->stdout_buf_clear($pid);

Clears stdout buffer for process $pid. Returns string containing buffer contents on success, otherwise undef.

=cut

sub stdout_buf_clear {
	return shift->stdout_buf($_[0], 1);
}

=head2 stderr_buf

 # just get it
 $buf = $mojox_run->stderr_buf($pid);
 # get and drain
 $buf = $mojox_run->stderr_buf($pid, 1);

Returns contents of stderr buffer for process $pid on success, otherwise undef.

Internal buffer is cleared if invoked with non-zero second argument.

=cut

sub stderr_buf {
	my ($self, $pid, $clear) = @_;
	$clear = 0 unless (defined $clear);
	my $proc = $self->_getProcStruct($pid);
	return undef unless (defined $proc);
	return undef if ($proc->{out_locked});

	# clear buffer?
	$proc->{buf_stderr} = '' if ($clear);
	return $proc->{buf_stderr};
}

=head2 stderr_buf_clear

 $buf = $mojox_run->stderr_buf_clear($pid);

Clears stderr buffer for process $pid. Returns empty string on success, otherwise undef.

=cut

sub stderr_buf_clear {
	return shift->stderr_buf($_[0], 1);
}

=head2 kill

 $mojox_run->kill($pid [, $signal = 15]);

Kills process $pid with specified signal. Returns 1 on success, otherwise 0.

=cut

sub kill {
	my ($self, $pid, $signal) = @_;
	$signal = 15 unless (defined $signal);
	my $proc = $self->_getProcStruct($pid);
	return 0 unless (defined $proc);

	# kill the process...
	unless (kill($signal, $pid)) {
		$self->{_error} = "Unable to send signal $signal to process $pid: $!";
		return 0;
	}
	return 1;
}

=head2 log_level ([$level])

Gets or sets loglevel for private logger instance. See L<Mojo::Log> for additional instructions.

=cut

sub log_level {
	my ($self, $level) = @_;
	if (defined $level) {
		my $prev_level = $_log->level();
		$_log->level($level);
	}
	return $_log->level();
}

=head2 num_running

Returns number of currently managed sub-processes.

=cut
sub num_running {
	my ($self) = @_;
	return scalar(keys %{$self->{_data}});
}

=head2 max_running

 $mojox_run->max_running($limit);

Returns currently set concurrently running subprocesses limit if called without arguments.
If called with integer argument sets new limit of concurrently spawned external processes
and returns old limit.

Value of 0 means that there is no limit. 

=cut
sub max_running {
	my $self = shift;
	# used provided argument?
	if (@_) {
		my $limit = shift;
		# invalid limit?
		return $self->{_max_running} unless (defined $limit);
		{ no warnings; $limit += 0; }
		my $old_limit = $self->{_max_running};
		
		# issue warning about overflow...
		if ($limit > 0 && $limit <= $self->num_running()) {
			$_log->warn(
				"New limit of $limit concurrently managed subprocesses is lower " .
				"than current number of managed subprocesses (" .
				$self->num_running() .
				"); new process creation will be refused until one or more " .
				" currently managed subprocesses won't exit."
			);
		}
		
		# set new limit
		$self->{_max_running} = ($limit > 0) ? $limit : 0;

		# return old limit
		return $old_limit;
	} else {
		return $self->{_max_running};
	}
}

=head2 ioloop

 # get
 $loop = $mojox_run->ioloop();
 # set
 $mojox_run->ioloop($loop);

Returns currently used ioloop if called without arguments. Currently
used IO loop if changed invoked with initialized L<Mojo::IOLoop> argument -
you better be sure what you're doing! 

=cut

sub ioloop {
	my ($self, $loop) = @_;
	# no valid $loop argument?
	unless (defined $loop && blessed($loop) && $loop->isa('Mojo::IOLoop')) {
		# custom loop?
		return $self->{_loop} if (defined $self->{_loop});
		# return singleton loop
		return Mojo::IOLoop->singleton();
	}
	
	# assign custom ioloop
	$self->{_loop} = $loop;
	return $self->{_loop};
}

##################################################
#                PRIVATE METHODS                 #
##################################################

sub __handle_cb {
	my $self = shift;
	my $pid = shift;
	my $name = shift;

	$self->{_error} = '';

	my $proc = $self->_getProcStruct($pid);
	return undef unless (defined $proc);

	my $key = $name . '_cb';
	unless (exists($proc->{$key})) {
		$self->{_error} = "Invalid callback name: $name";
		return undef;
	}

	# save old callback
	my $old_cb = $proc->{$key};
	$self->{_error} = "Handle $name: no callback defined." unless (defined $old_cb);

	# should we set another callback?
	if (@_) {
		my $new_cb = shift;
		unless (ref($new_cb) eq 'CODE') {
			$self->{_error} = "Second argument must be code reference.";
			return undef;
		}
		if ($proc->{out_locked} && ($name eq 'stdout' || $name eq 'stderr')) {
			$self->{_error} = "Process was started by spawn_sub. Ouput streams are locked.";
			return undef;
		}

		# apply callback
		$proc->{$key} = $new_cb;
	}

	# return it...
	return $old_cb;
}

sub _spawn {
	my ($self, $o) = @_;
	unless (defined $o && ref($o) eq 'HASH') {
		$self->{_error} =
		  "Invalid spawning options. THIS IS A " . __PACKAGE__ . ' BUG!!!';
		return 0;
	}
	
	# can we spawn another subprocess?
	if ($self->max_running() > 0) {
		if ($self->num_running() >= $self->max_running()) {
			$self->{_error} = "Unable to spawn another subprocess: " .
			"Limit of " . $self->num_running() . " concurrently spawned process(es) is reached.";
			return 0;
		}
	}

	# time to do the job
	$_log->debug("Spawning command "
		  . "[timeout: "
		  . ($o->{exec_timeout} > 0) ? sprintf("%-.3f seconds]", $o->{exec_timeout}) : "none"
		  . ": $o->{cmd}");

	# prepare stdio handles
	my $stdin  = MojoX::HandleRun->new();
	my $stdout = MojoX::HandleRun->new();
	my $stderr = MojoX::HandleRun->new();

	# prepare spawn structure
	my $proc = {
		out_locked   => 0,
		time_started => time(),
		pid          => 0,
		cmd          => $o->{cmd},
		running      => 1,
		error        => undef,
		stdin_cb  => ($o->{stdin_cb})  ? $o->{stdin_cb}  : undef,
		stdout_cb => ($o->{stdout_cb}) ? $o->{stdout_cb} : undef,
		stderr_cb => ($o->{stderr_cb}) ? $o->{stderr_cb} : undef,
		exit_cb   => ($o->{exit_cb})   ? $o->{exit_cb}   : undef,
		timeout   => $o->{exec_timeout},
		buf_stdout => '',
		buf_stderr => '',
		id_stdin   => undef,
		id_stdout  => undef,
		id_stderr  => undef,
		id_timeout => undef,
	};

	# spawn command
	my $pid = undef;
	eval { $pid = MojoX::_Open3::open3($stdin, $stdout, $stderr, $o->{cmd}) };
	if ($@) {
		$self->{_error} = "Exception while starting command '$o->{cmd}': $@";
		return 0;
	}
	unless (defined $pid && $pid > 0) {
		$self->{_error} = "Error starting external command: $!";
		return 0;
	}
	$_log->debug("Subprocess spawned as pid $pid.");
	$proc->{pid} = $pid;

	# make handles non-blocking...
	$stdin->blocking(0);
	$stdout->blocking(0);
	$stderr->blocking(0);

	my $loop = $self->ioloop();

	# exec timeout
	if (defined $o->{exec_timeout} && $o->{exec_timeout} > 0) {
		$_log->debug(
			"[process $pid]: Setting execution timeout to " .
			sprintf("%-.3f seconds.", $o->{exec_timeout})
		);
		my $timer = $loop->timer(
			$o->{exec_timeout},
			sub { _timeout_cb($self, $pid) }
		);

		# save timer
		$proc->{id_timeout} = $timer;
	}

	# add them to ioloop
	my $id_stdout = $loop->connect(
		socket   => $stdout,
		handle   => $stdout,
		on_error => sub { _error_cb($self, $pid, @_) },
		on_hup   => sub { _hup_cb($self, $pid, @_) },
		on_read  => sub { _read_cb($self, $pid, @_) },
	);
	my $id_stderr = $loop->connect(
		socket   => $stderr,
		handle   => $stderr,
		on_error => sub { _error_cb($self, $pid, @_) },
		on_hup   => sub { _hup_cb($self, $pid, @_) },
		on_read  => sub { _read_cb($self, $pid, @_) },
	);
	my $id_stdin = $loop->connect(
		socket   => $stdin,
		handle   => $stdin,
		on_error => sub { _error_cb($self, $pid, @_) },
		on_hup   => sub { _hup_cb($self, $pid, @_) },
		on_read  => sub { _read_cb($self, $pid, @_) },
	);
	
	{ 
		no warnings;
		$_log->debug("[process $pid]: handles: stdin=$id_stdin, stdout=$id_stdout, stderr=$id_stderr");
	}
	
	unless (defined $id_stdout && defined $id_stderr && defined $id_stdin) {
		$self->{_error} = "Didn't get all handles from IOLoop. This is extremely weird, spawned process was killed.";
		CORE::kill(9, $pid);
		return 0;
	}

	# STDIO FD timeouts
	my $io_timeout = $o->{exec_timeout};
	# no timeout at all? set insanely large value...
	unless (defined $io_timeout && $io_timeout > 0) {
		# i guess that there are no perl processes
		# that live for 10 years...
		$io_timeout = VERY_LONG_TIMEOUT;
	}
	# I/O timeout should be for at least one io loop's
	# tick longer than execution timeout so that command
	# closes streams itself, otherwise streams can be
	# closed by ioloop which would result in incomplete
	# output capture.
	$io_timeout++;
	
	# apply stdio timeouts
	$loop->connection_timeout($id_stdout, $io_timeout);
	$loop->connection_timeout($id_stderr, $io_timeout);
	$loop->connection_timeout($id_stdin, $io_timeout);
	$_log->debug("[process $pid]: stdio stream timeout set to $io_timeout seconds.");

	# save loop fd ids
	$proc->{id_stdin}  = $id_stdin;
	$proc->{id_stdout} = $id_stdout;
	$proc->{id_stderr} = $id_stderr;

	# save structure...
	$self->{_data}->{$pid} = $proc;

	return $pid;
}

sub _lock_output {
	my ($self, $pid) = @_;

	# get process struct...
	my $proc = $self->_getProcStruct($pid);
	return 0 unless (defined $proc);

	$proc->{out_locked} = 1;
	return 1;
}

sub _read_cb {
	my ($self, $pid, $loop, $id, $chunk) = @_;
	my $len = 0;
	$len = length($chunk) if (defined $chunk);

	# no data?
	return 0 unless ($len > 0);

	# get process struct...
	my $proc = $self->_getProcStruct($pid);
	return 0 unless (defined $proc);

	# id can be stdout or stderr (stdin is write-only)
	if (defined $proc->{id_stdout} && $proc->{id_stdout} eq $id) {

		# do we have callback?
		if (defined $proc->{stdout_cb}) {
			$_log->debug("[process $pid]: (handle: $id) Invoking STDOUT callback.");
			eval { $proc->{stdout_cb}->($pid, $chunk) };
			if ($@) {
				$_log->error("[process $pid]: (handle: $id) Exception in stdout_cb: $@");
			}
		}
		else {

			# append to buffer
			$_log->debug(
				"[process $pid]: (handle: $id) Appending $len bytes to STDOUT buffer.");
			$proc->{buf_stdout} .= $chunk;
		}
	}
	elsif (defined $proc->{id_stderr} && $proc->{id_stderr} eq $id) {

		# do we have callback?
		if (defined $proc->{stderr_cb}) {
			$_log->debug("[process $pid]: (handle: $id) Invoking STDERR callback.");
			eval { $proc->{stderr_cb}->($pid, $chunk) };
			if ($@) {
				$_log->error("[process $pid]: (handle: $id) Exception in stderr_cb: $@");
			}
		}
		else {

			# append to buffer
			$_log->debug(
				"[process $pid]: (handle: $id) Appending $len bytes to STDERR buffer.");
			$proc->{buf_stderr} .= $chunk;
		}
	}
	else {
		$_log->debug("Got data from unmanaged handle $id; ignoring.");
		return 0;
	}
}

sub _hup_cb {
	my ($self, $pid, $loop, $id) = @_;
	# just drop the goddamn handle...
	return $self->_dropHandle($pid, $loop, $id);
}

sub _dropHandle {
	my ($self, $pid, $loop, $id) = @_;

	# get process structure
	my $proc = $self->_getProcStruct($pid);
	return 0 unless (defined $proc);

	if (defined $proc->{id_stdout} && $proc->{id_stdout} eq $id) {
		$proc->{id_stdout} = undef;
		$_log->debug("[process $pid]: STDOUT closed.");
	}
	elsif (defined $proc->{id_stderr} && $proc->{id_stderr} eq $id) {
		$proc->{id_stderr} = undef;
		$_log->debug("[process $pid]: STDERR closed.");
	}
	elsif (defined $proc->{id_stdin} && $proc->{id_stdin} eq $id) {
		$proc->{id_stdin} = undef;
		$_log->debug("[process $pid]: STDIN closed.");
	}
	else {
		$_log->debug("[process $pid]: Got HUP for unmanaged handle $id; ignoring.");
		return 0;
	}

	# drop handle...
	$loop->drop($id);

	# check if we're ready to deliver response
	$self->_checkIfComplete($pid);
}

sub _checkIfComplete {
	my ($self, $pid, $force) = @_;
	$force = 0 unless (defined $force);

	# get process structure
	my $proc = $self->_getProcStruct($pid);
	return 0 unless (defined $proc);

	# is process execution really complete?
	# a) it can be forced
	# b) all streams should be closed && sigchld must for pid
	if ($force
		|| (
			!$proc->{running}
			&& !defined $proc->{id_stdin}
			&& !defined $proc->{id_stdout}
			&& !defined $proc->{id_stderr}
			)
		)
	{
		$_log->debug(
			"[process $pid]: All streams closed, process execution complete.")
		  unless ($force);
		$proc->{time_duration_total} = time() - $proc->{time_started};

		# fire exit callback!
		if (defined $proc->{exit_cb} && ref($proc->{exit_cb}) eq 'CODE') {

			# prepare callback structure
			my $cb_d = {
				cmd => (ref($proc->{cmd}) eq 'CODE') ?
					'CODE' :
					(
						(ref($proc->{cmd}) eq 'ARRAY') ?
							join(' ', @{$proc->{cmd}}) :
							$proc->{cmd}
					),
				exit_status         => $proc->{exit_val},
				exit_signal         => $proc->{exit_signal},
				exit_core           => $proc->{exit_core},
				error               => ($force) ? "Forced process termination." : $proc->{error},
				stdout              => $proc->{buf_stdout},
				stderr              => $proc->{buf_stderr},
				time_started        => $proc->{time_started},
				time_stopped        => $proc->{time_stopped},
				time_duration_exec  => $proc->{time_duration_exec},
				time_duration_total => $proc->{time_duration_total},
			};

			# safely invoke callback
			$_log->debug("[process $pid]: invoking exit_cb callback.") if (defined $_log);
			eval { $proc->{exit_cb}->($pid, $cb_d); };
			if ($@) {
				$_log->error("[process $pid]: Error running exit_cb: $@") if (defined $_log);
			}
		}
		else {
			$_log->error("[process $pid]: No exit_cb callback!");
		}

		# destroy process structure
		$self->_destroyProcStruct($pid);
	}
}

sub _destroyProcStruct {
	my ($self, $pid) = @_;
	delete($self->{_data}->{$pid});
}

sub _error_cb {
	my ($self, $pid, $loop, $id, $err) = @_;
	$_log->debug("[process $pid]: Error on handle $id: $err");
	return $self->_dropHandle($pid, $loop, $id);
}

sub _timeout_cb {
	my ($self, $pid) = @_;
	my $proc = $self->_getProcStruct($pid);
	return 0 unless (defined $proc);

	# drop timer (can't hurt...)
	if (defined $proc->{id_timeout}) {
		$self->ioloop()->drop($proc->{id_timeout});
		$proc->{id_timeout} = undef;
	}

	# is process still alive?
	return 0 unless (CORE::kill(0, $pid));

	$_log->debug("[process $pid]: Execution timeout ("
		  . sprintf("%-.3f seconds).", $proc->{timeout})
		  . " Killing process.");

	# kill the motherfucker!
	unless (CORE::kill(9, $pid)) {
		$_log->warn("[process $pid]: Unable to kill process: $!");
	}

	$proc->{error} = "Execution timeout.";

	# sigchld handler will do the rest for us...
	return 1;
}

sub _init {
	my $self = shift;

	# last error message
	$self->{_error} = '';

	# stored exec structs
	$self->{_data} = {};
	
	# ioloop object...
	$self->{_ioloop} = undef;
	
	# maximum running limit
	$self->{_max_running} = 0;

	# install SIGCHLD handler
	$SIG{'CHLD'} = sub { _sig_chld($self, @_) };
}

sub _getProcStruct {
	my ($self, $pid) = @_;
	no warnings;
	my $err = "[process $pid]: Unable to get process data structure: ";
	unless (defined $pid) {
		$self->{_error} = $err . "Undefined pid.";
		return undef;
	}
	unless (exists($self->{_data}->{$pid})
		&& defined $self->{_data}->{$pid})
	{
		$self->{_error} = $err . "Non-managed process pid: $pid";
		return undef;
	}

	return $self->{_data}->{$pid};
}

sub _getRunStruct {
	my ($self, $opt) = @_;
	my $s = {
		cmd          => undef,
		stdout_cb    => undef,
		stderr_cb    => undef,
		error_cb     => undef,
		exit_cb      => undef,
		exec_timeout => 0,
	};

	# apply user defined vars...
	map {
		if (exists($s->{$_}))
		{
			$s->{$_} = $opt->{$_};
		}
	} keys %{$opt};

	return $s;
}

sub _validateRunStruct {
	my ($self, $s) = @_;

	# command?
	unless (defined $s->{cmd}) { #} && length($s->{cmd}) > 0) {
		$self->{_error} = "Undefined command.";
		return 0;
	}
	# check command...
	my $cmd_ref = ref($s->{cmd});
	if ($cmd_ref eq '') {
		unless (length($s->{cmd}) > 0) {
			$self->{_error} = "Zero-length command.";
			return 0;
		}
	} else {
		unless ($cmd_ref eq 'CODE' || $cmd_ref eq 'ARRAY') {
			$self->{_error} = "Command can be pure scalar, arrayref or coderef.";
			return 0;
		}
	}

	# callbacks...
	if (defined $s->{stdout_cb} && ref($s->{stdout_cb}) ne 'CODE') {
		$self->{_error} = "STDOUT callback defined, but is not code reference.";
		return 0;
	}
	if (defined $s->{stderr_cb} && ref($s->{stderr_cb}) ne 'CODE') {
		$self->{_error} = "STDERR callback defined, but is not code reference.";
		return 0;
	}
	if (defined $s->{exit_cb} && ref($s->{exit_cb}) ne 'CODE') {
		$self->{_error} =
		  "Process exit_cb callback defined, but is not code reference.";
		return 0;
	}

	# exec timeout
	{ no warnings; $s->{exec_timeout} += 0; }

	return 1;
}

sub _procCleanup {
	my ($self, $pid, $exit_val, $signum, $core) = @_;
	my $proc = $self->_getProcStruct($pid);
	unless (defined $proc) {
		no warnings;
		$_log->warn(
			"Untracked process pid $pid exited with exit status $exit_val by signal $signum, core: $core."
		);
		return 0;
	}

	$_log->debug(
		"[process $pid]: Got SIGCHLD, " .
		"exited with exit status: $exit_val by signal $signum"
		  . (($core) ? "with core dump" : "")
		  . '.');

	$proc->{exit_val}    = $exit_val;
	$proc->{exit_signal} = $signum;
	$proc->{exit_core}   = $core;

	# command timings...
	my $te = time();
	$proc->{time_stopped}       = $te;
	$proc->{time_duration_exec} = $te - $proc->{time_started};

	# this process is no longer running
	$proc->{running} = 0;

	# destroy timer if it was defined
	if (defined $proc->{id_timeout}) {
		$_log->debug(
			"[process $pid]: Removing timeout handler $proc->{id_timeout}.");
		$self->ioloop()->drop($proc->{id_timeout});
		$proc->{id_timeout} = undef;
	}

	# check if we're ready to deliver response
	$self->_checkIfComplete($pid);
}

sub _sig_chld {
	my ($self) = @_;

	# $_log->debug('SIGCHLD hander startup: ' . join(", ", @_));
	my $i = 0;
	while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
		$i++;
		my $exit_val = $? >> 8;
		my $signum   = $? & 127;
		my $core     = $? & 128;

		# do process cleanup
		$self->_procCleanup($pid, $exit_val, $signum, $core);
	}
	$_log->debug("SIGCHLD handler cleaned up after $i process(es).")
	  if ($i > 0);
}

=head1 BUGS/CAVEATS

There seem to be problems on some B<OpenBSD, DragonFly and Solaris> systems
in conjunction with L<Mojo::IOLoop> implementation. Error manifests itself with the
following warning message:

 Filehandle GEN3 opened only for input at /usr/libdata/perl5/i386-openbsd/5.10.1/IO/Handle.pm line 465.

L<IO::Handle>'s syswrite method is called by L<Mojo::IOLoop>'s _write, but there is no good reason
to write to process stdout or stderr... I'm investigating, feel free to contact me regarding this
issue.

=head1 AUTHOR

"Brane F. Gracnar", C<< <"bfg at frost.ath.cx"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-run at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Run>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Run


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Run>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Run>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Run>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Run/>

=item * Source repository

L<https://github.com/bfg/mojox-run>

=back


=head1 ACKNOWLEDGEMENTS

This module was inspired by L<POE::Wheel::Run> by Rocco Caputo; module includes
patched version of L<IPC::Open3> from Perl distribution which allows perl coderef
execution.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011, Brane F. Gracnar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of MojoX::Run