package Parallel::Jobs;

# Start a number of jobs in parallel.  Caller is responsible for
# deciding how many to start at a time.  Allow fine-grained control
# over stdin, stdout and stderr of every job.

use 5.006;
use strict;
use warnings;
use Exporter;
use Carp;
use IPC::Open3;
use File::Spec;
use POSIX qw(:sys_wait_h);
use File::Temp qw(tempfile);

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION %pids %dead_pids
	    %stdout_handles %stderr_handles $debug @events);

@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw(start_job watch_jobs);
$VERSION   = 0.09;

sub new_handle ();
sub is_our_handle ($);

# If the first argument is a hashref, it contains zero or more of
# these parameters:
#
# stdin_file - give the job input from the specified file
# stdin_handle - give the job input from the specified file handle
# stdout_handle - send the job's stdout to the specified file handle
# stdout_capture - capture the stdout while monitoring running jobs
# stderr_handle - send the job's stderr to the specified file handle
# stderr_capture - capture the stderr while monitoring running jobs
#
# By default, the job gets input from /dev/null and stdout and stderr
# are unmodified.
#
# Remaining arguments, or all arguments if the first argument isn't a
# hashref, are the command to execute.
#
# Returns the PID of the started job, or undef on error.

my($fh_counter) = 0;
 
sub start_job {
    my(%params);
    my(@cmd);
    my($stdin_handle, $stdout_handle, $stderr_handle);
    my($capture_stdout, $capture_stderr);
    my($pid);
    my(@to_close);

    if ($_[0] eq __PACKAGE__) {
	# Should we flame at the user for calling this function as a
	# method instead of a function call?  Not sure.
	shift;
    }

    if (! @_) {
	carp(__PACKAGE__ . ": No arguments specified");
	return undef;
    }
    elsif (ref $_[0] eq 'HASH') {
	%params = %{shift @_};
	@cmd = @_;
    }
    elsif (ref $_[0] eq 'SCALAR') {
	@cmd = (${shift @_});
	push(@cmd, @_);
    }
    else {
	@cmd = @_;
    }

    if ($params{'stdin_handle'}) {
	$stdin_handle = new_handle;
	no strict 'refs';
	open($stdin_handle, '<&' . fileno($params{'stdin_handle'}))
	    or croak "Couldn't reopen fhandle $params{'stdin_handle'}: $!";
	delete $params{'stdin_handle'};
    }
    else {
	$params{'stdin_file'} = '/dev/null'
	    unless $params{'stdin_file'};
    }

    if ($params{'stdin_file'}) {
	if ($stdin_handle) {
	    carp(__PACKAGE__ . ": Multiple stdin sources specified");
	    return undef;
	}
	$stdin_handle = new_handle;
	no strict 'refs';
	if (! open($stdin_handle, $params{'stdin_file'})) {
	    carp(__PACKAGE__ . ": open($params{'stdin_file'}): $!");
	    return undef;
	}
	delete $params{'stdin_file'};
    }

    $stdin_handle = '<&' . $stdin_handle;

    if ($params{'stdout_handle'}) {
	$stdout_handle = new_handle;
	no strict 'refs';
	open($stdout_handle, '>&' . fileno($params{'stdout_handle'}))
	    or croak "Couldn't reopen fhandle $params{'stdout_handle'}: $!";
	warn("Stdout file descriptor (from handle) is " .
	     fileno($stdout_handle) . "\n") if ($debug);
	push(@to_close, $stdout_handle);
	$stdout_handle = '>&' . $stdout_handle;
	delete $params{'stdout_handle'};
    }

    if ($params{'stdout_capture'}) {
	if ($stdout_handle) {
	    carp(__PACKAGE__ . ": Multiple stdout sources specified");
	    return undef;
	}
	delete $params{'stdout_capture'};
	$stdout_handle = new_handle;
	$capture_stdout = 1;
    }
    elsif (! $stdout_handle) {
	$stdout_handle = ">&STDOUT";
    }

    if ($params{'stderr_handle'}) {
	$stderr_handle = new_handle;
	no strict 'refs';
	open($stderr_handle, '>&' . fileno($params{'stderr_handle'}))
	    or croak "Couldn't reopen fhandle $params{'stderr_handle'}: $!";
	push(@to_close, $stderr_handle);
	$stderr_handle = '>&' . $stderr_handle;
	delete $params{'stderr_handle'};
    }

    if ($params{'stderr_capture'}) {
	if ($stderr_handle) {
	    carp(__PACKAGE__ . ": Multiple stderr sources specified");
	    return undef;
	}
	delete $params{'stderr_capture'};
	$stderr_handle = new_handle;
	$capture_stderr = 1;
    }
    elsif (! $stderr_handle) {
	$stderr_handle = ">&STDERR";
    }

    $pid = eval {
	warn("Calling open3(" .
	     ($stdin_handle ? $stdin_handle : "undef") . ", " .
	     ($stdout_handle ? $stdout_handle : "undef") . ", " .
	     ($stderr_handle ? $stderr_handle : "undef") . ", " .
	     "@cmd)\n") if ($debug);
	open3($stdin_handle, $stdout_handle, $stderr_handle, @cmd);
    };

    if ($@) {
	carp(__PACKAGE__ . ": $@");
	return undef;
    }

    # If we skipped the exec in open3, we're still in the Perl child.
    return $pid unless $pid;

    $pids{$pid}++;
    if ($capture_stdout) {
	$stdout_handles{$pid} = $stdout_handle;
	warn("Stdout fd of $pid is " . fileno($stdout_handles{$pid}) .
	     "\n") if ($debug);
    }
    if ($capture_stderr) {
	$stderr_handles{$pid} = $stderr_handle;
	warn("Stderr fd of $pid is " . fileno($stderr_handles{$pid}) .
	     "\n") if ($debug);
    }

    map(close($_), @to_close);

    return $pid;
}

my($fhnum) = 0;
my($fh_pat) = sprintf('^%s::fh\d+$', __PACKAGE__);

sub new_handle () {
    sprintf("%s::fh%d", __PACKAGE__, $fhnum++);
}

sub is_our_handle ($) {
    $_[0] =~ /$fh_pat/o;
}

sub watch_jobs {
    my(%args);
    my(@pid_only);
    my(%stdout_to_pid, %stderr_to_pid);
    my($nfound, $waiting);
    my($pid, $type);
    my($ret);
    my($rbits, $ebits);
    my(@pids) = keys %pids;
    my(@dead_pids) = keys %dead_pids;

    if (ref $_[0] eq 'HASH') {
	%args = %{$_[0]};
    }

    warn("watch_jobs: pids(@pids) dead_pids(@dead_pids) #events=",
	 scalar(@events), "\n") if ($debug);
    if (! (@pids || @dead_pids || @events)) {
	return ();
    }

    foreach my $pid (@pids, @dead_pids) {
	if (! ($stdout_handles{$pid} || $stderr_handles{$pid})) {
	    push(@pid_only, $pid);
	}
	else {
	    if ($stdout_handles{$pid}) {
		$stdout_to_pid{$stdout_handles{$pid}} = $pid;
	    }
	    if ($stderr_handles{$pid}) {
		$stderr_to_pid{$stderr_handles{$pid}} = $pid;
	    }
	}
    }

    if (! (@dead_pids || $args{nohang})) {
	if (@pid_only == @pids) {
	    if (@events) {
		return(@{shift @events});
	    }

	    warn "Waiting for @pids to exit\n" if ($debug);
	    $pid = wait;
	    if ($pid == -1) {
		# This shouldn't happen.  Perhaps the caller waited on
		# processes himself.  Shame.
		return ();
	    }
	    warn "$pid exited (wait)\n" if ($debug);
	    delete $pids{$pid};
	    return($pid, 'EXIT', $?);
	}
    }

    foreach my $pid (@pids) {
	if (waitpid($pid, WNOHANG) > 0) {
	    warn "$pid exited (waitpid)\n" if ($debug);
	    delete $pids{$pid};
	    if ($stdout_handles{$pid} || $stderr_handles{$pid}) {
		$dead_pids{$pid}++;
	    }
	    push(@events, [$pid, 'EXIT', $?]);
	}
    }

    while (1) {
	$rbits = '';
	map((vec($rbits, fileno($_), 1) = 1),
	    keys %stdout_to_pid,
	    keys %stderr_to_pid);

	warn "Calling select() to wait for output from jobs\n" if ($debug);

	$nfound = select($rbits, undef, $ebits = $rbits,
			 (@events || $args{nohang}) ? 0 : undef);

	if (! $nfound) {
	    if (! (@events || $args{nohang})) {
		die(__PACKAGE__ . ": Internal error: Select unexpectedly " .
		    "returned no pending data") if (! $nfound);
	    }
	    last;
	}

	($waiting) = grep(vec($rbits, fileno($_), 1) || vec($ebits, fileno($_), 1),
			  keys %stdout_to_pid, keys %stderr_to_pid);

	die(__PACKAGE__ . ": Internal error: Select returned " .
	    "an unexpected bit") if (! $waiting);

	if (($pid = $stdout_to_pid{$waiting})) {
	    $type = 'STDOUT';
	}
	elsif (($pid = $stderr_to_pid{$waiting})) {
	    $type = 'STDERR';
	}
	else {
	    die(__PACKAGE__ . ": Internal error: unexpected file handle");
	}

	# Read all pending data
	my($nfound2);
	my($size) = 1024;
	my($data) = '';
	do {
	    $rbits = '';
	    vec($rbits, fileno($waiting), 1) = 1;
	    $ret = sysread($waiting, $data, $size, length($data));
	    $size *= 2;
	    $nfound2 = select($rbits, undef, $ebits = $rbits, 0);
	} while ($ret && $nfound2);

	if ($data ne '') {
	    warn "Got $type output ($data) from $pid\n" if ($debug);
	}
	else {
	    # Got EOF
	    warn "Got $type EOF from $pid\n" if ($debug);
	    close($waiting);
	    if ($type eq 'STDOUT') {
		delete $stdout_to_pid{$stdout_handles{$pid}};
		delete $stdout_handles{$pid};
	    }
	    if ($type eq 'STDERR') {
		delete $stderr_to_pid{$stderr_handles{$pid}};
		delete $stderr_handles{$pid};
	    }
	    if ($dead_pids{$pid} &&
		! ($stderr_handles{$pid} || $stdout_handles{$pid})) {
		delete $dead_pids{$pid};
	    }
	}

	push(@events, [$pid, $type, $data]);
    }

    if (@events) {
	return(@{shift @events});
    }
    else {
	return ();
    }
}

# If the argument is true, operate silently.

sub test ($) {
    my($fh, $outfile) = tempfile(__PACKAGE__ . ".testXXXX");
    my(@tests);

    $debug = ! (@_ && $_[0]);

    my(@commands) = (
		     [ 'true', ],
		     [ 'sleep', '1' ],
		     [ 'echo foo' ],
		     [ 'echo bar 1>&2' ],
		     ['sleep 1; echo baz; sleep 1; echo screlt' ],
		     );
    @tests = ({}, {stdout_capture=>1}, {stderr_capture=>1},
	      {stdout_capture=>1,stderr_capture=>1});
    if ($outfile) {
	push(@tests, {stdout_handle=>$fh});
    }

    if (! $debug) {
	no warnings 'once';
	my($devnull) = File::Spec->devnull;
	open(DEVNULL, ">$devnull") or die "open($devnull): $!";
	open(OLD_STDOUT, ">&STDOUT");
	open(OLD_STDERR, ">&STDERR");
    }

    foreach my $params (@tests) {
	my(%params) = %{$params};
	my($pid, $event, $data);

	if ($debug) {
	    print "Params:";
	    map((print " $_ => $params{$_}"), keys %params);
	    print "\n";
	}
	else {
	    if (! ($params{'stdout_handle'} || $params{'stdout_capture'})) {
		open(STDOUT, ">&DEVNULL");
	    }
	    if (! ($params{'stderr_handle'} || $params{'stderr_capture'})) {
		open(STDERR, ">&DEVNULL");
	    }
	}

	foreach my $command (@commands) {
	    $pid = start_job($params, @{$command});
	    die if (! $pid);
	    print "Started @{$command} ($pid)\n" if ($debug);
	}
	 
	while (($pid, $event, $data) = watch_jobs()) {
	    print "pid=$pid, event=$event, data=$data\n" if ($debug);
	}

	if (! $debug) {
	    if (! ($params{'stdout_handle'} || $params{'stdout_capture'})) {
		open(STDOUT, ">&OLD_STDOUT");
	    }

	    if (! ($params{'stderr_handle'} || $params{'stderr_capture'})) {
		open(STDERR, ">&OLD_STDERR");
	    }
	}
    }

    if ($outfile) {
	my($text);

	close($fh);

	{
	    local($/) = undef;
	    open(OUTFILE, $outfile) || die "open($outfile): $!";
	    $text = <OUTFILE>;
	    close(OUTFILE);
	}

	# If we're on an OS where different file descriptors to the same
	# file keep different seek pointers, then the data written by
	# the earlier command above could be overwritten by the data
	# written by the later command, so we need to detect that
	# possibility, hence the regexp below.
	if ($text !~ /^(?:foo\n)?baz\nscrelt\n$/) {
	    die "Unexpected data in output file: $text";
	}

	start_job({stdin_file=>$outfile}, 'cat');
	watch_jobs();

	open(OUTFILE, $outfile) || croak;

	start_job({stdin_handle=>*OUTFILE{IO}}, 'cat');
	watch_jobs();

	unlink($outfile);
    }
}
		     
1;

################ Documentation ################

=head1 NAME

Parallel::Jobs - run jobs in parallel with access to their stdout and stderr

=head1 SYNOPSIS

  use Parallel::Jobs;
  use Parallel::Jobs qw(start_job watch_jobs);

  $pid = Parallel::Jobs::start_job('cmd', ... args ...);
  $pid = Parallel::Jobs::start_job('cmd ... args ...');
  $pid = Parallel::Jobs::start_job({ stdin_file => filename |
				     stdin_handle => *HANDLE,
				     stdout_handle => *HANDLE |
				     stdout_capture => 1,
				     stderr_handle => *HANDLE |
				     stderr_capture => 1 },
				     ... cmd as above ...);

  ($pid, $event, $data) = Parallel::Jobs::watch_jobs();
  ($pid, $event, $data) = Parallel::Jobs::watch_jobs({nohang => 1});

=head1 DESCRIPTION

The Parallel::Jobs module allows you to run multiple jobs in parallel
with fine-grained control over their stdin, stdout and stderr.  That
control is the biggest difference between this module and others such
as Parallel::ForkManager.

You can specify the command to run as a single string or as a list
specifying the command and its arguments, as in L<IPC::Open3>.  If
your version of IPC::Open3 supports '-' as the command,
Parallel::Jobs::start_job() will fork to a Perl child in a manner
analogous to C<open(FOO, "-|")>.

If your first argument is a reference to a hash, it can specify the
parameters shown above.  By default, stdin for each job is set to
/dev/null and stdout and stderr are set to the stdout and stderr of
the calling process.

If you specify stdin_handle, stdout_handle or stderr_handle, the
handle will be copied the original handle will thus not be modified.

Each time you call Parallel::Jobs::watch_jobs(), it will return the
process ID of the job with which an event has occured, the event type,
and the data associated with that event.  If there are no more jobs to
watch, watch_jobs() will return undef. If you want to poll for pending
events without hanging if there are none currently available, specify
a hash with the key "nohang" set to a true value.

The relevant events are as follows:

=over

=item EXIT

The indicated process has exited.  The returned data is the value of
$? from the exited process.  The process has already been waited for
(i.e., you don't need to do any cleanup on it).

=item STDOUT

Output has been received on stdout.  The returned data is the output
that was received, or an empty string if EOF was received.

=item STDERR

Output has been received on stderr.  The returned data is the output
that was received, or an empty string if EOF was received.

=back

Note that it is possible to receive STDOUT or STDERR events from a
process after its EXIT event, i.e., you may receive an EXIT event
before you've read all of a process's output.

=head1 AUTHOR

Jonathan Kamens E<lt>jik@kamens.usE<gt>

=head1 CREDITS

This module was written and is maintained by Jonathan Kamens
(originally E<lt>jik@worldwinner.comE<gt>, currently
E<lt>jik@kamens.usE<gt>).  In addition, the following people
contributed bug fixes, enhancements, and/or useful suggestions:

=over

=item Paul GABORIT E<lt>gaborit@enstimac.frE<gt>

=item Adam Spiers E<lt>perl@adamspiers.orgE<gt>

=item Greg Lindahl E<lt>greg@blekko.comE<gt>

=back

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright 2002-2003 by WorldWinner.com, Inc.

=item Copyright 2012, 2013 Jonathan Kamens.

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
