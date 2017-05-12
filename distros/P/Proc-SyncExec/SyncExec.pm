# $Id: SyncExec.pm,v 1.5 2005/02/04 12:15:57 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

=head1 NAME

Proc::SyncExec - Spawn processes but report exec() errors

=head1 SYNOPSIS

    # Normal-looking piped opens which properly report exec() errors in $!:
    sync_open WRITER_FH, "|command -with args" or die $!;
    sync_open READER_FH, "command -with args|" or die $!;

    # Synchronized fork/exec which reports exec errors in $!:
    $pid = sync_exec $command, @arg;
    $pid = sync_exec $code_ref, $cmd, @arg;	# run code after fork in kid

    # fork() which retries if it fails, then croaks() if it still fails.
    $pid = fork_retry;
    $pid = fork_retry 100;		# retry 100 times rather than 5
    $pid = fork_retry 100, 2;		# sleep 2 rather than 5 seconds between

    # A couple of interfaces similar to sync_open() but which let you
    # avoid the shell:
    $pid = sync_fhpopen_noshell READERFH, 'r', @command;
    $pid = sync_fhpopen_noshell WRITERFH, 'w', @command;
    $fh = sync_popen_noshell 'r', @command_which_outputs;
    $fh = sync_popen_noshell 'w', @command_which_inputs;
    ($fh, $pid) = sync_popen_noshell 'r', @command_which_outputs;
    ($fh, $pid)= sync_popen_noshell 'w', @command_which_inputs;

=head1 DESCRIPTION

This module contains functions for synchronized process spawning with
full error return.  If the child's exec() call fails the reason for the
failure is reported back to the parent.

These functions will croak() if they encounter an unexpected system
error, such as a pipe() failure or a repeated fork() failure.

Nothing is exported by default.

=over

=cut

#';

package Proc::SyncExec;

use strict;
use vars	qw($VERSION @ISA @EXPORT_OK);

use Carp	qw(croak);
use Exporter	  ();
use Fcntl	qw(F_SETFD);
use POSIX	qw(EINTR);
use Symbol	qw(gensym qualify_to_ref);

$VERSION	= '1.01';
@ISA		= qw(Exporter);
@EXPORT_OK	= qw(fork_retry sync_exec sync_fhpopen_noshell
			sync_popen_noshell sync_open);

=item B<fork_retry> [I<max-retries> [I<sleep-between>]]

This function runs fork() until it succeeds or until I<max-retries>
(default 5) attempts have been made, sleeping I<sleep-between> seconds
(default 5) between attempts.  If the last fork() fails B<fork_retry>
croak()s.

=cut

sub fork_retry {
    @_ > 2 and croak "Usage: fork_retry max_retries=5 sleep_between=5";
    my ($max_retries, $sleep) = @_;
    my ($retries, $kid);

    $max_retries = 5 if !defined $max_retries or $max_retries < 0;
    $sleep = 5 if !defined $sleep or $sleep < 0;

    $retries = 0;
    while (!defined($kid = fork)) {
	croak "Can't fork: $!" if $retries++ >= $max_retries;
	sleep $sleep;
    }
    return $kid;
}

=item B<sync_exec> [I<code>] I<command>...

This function is similar to a fork()/exec() sequence but with a few
twists.

B<sync_exec> does not return until after the fork()ed child has already
performed its exec().  The synchronization this provides is useful in
some unusual circumstances.

Normally the pid of the child process is returned.  However, if the
child fails its exec() B<sync_exec> returns undef and sets $! to the
reason for the child's exec() failure.

Since the @cmd array is passed directly to Perl's exec() Perl might
choose to invoke the command via the shell if @cmd contains only one
element and it looks like it needs a shell to interpret it.  If this
happens the return value of B<sync_exec> only indicates whether the
exec() of the shell worked.

The optional initial I<code> argument must be a code reference.  If it
is present it is run in the child just before exec() is called.  You can
use this to set up redirections or whatever.  If I<code> returns false
no exec is performed, instead a failure is returned using the current $!
value (or EINTR if $! is 0).

If the fork() fails or if there is some other unexpected system error
B<sync_exec> croak()s rather than returning.

=cut

sub sync_exec {
    my $code = (@_ && ref $_[0] eq 'CODE') ? shift : undef;
    @_ or croak 'Usage: sync_exec [code] cmd [arg]...';
    my @cmd = @_;

    my ($reader, $writer) = (gensym, gensym);
    pipe $reader, $writer
	or croak "Can't pipe(): $!";
    my $pid = fork_retry;
    if (!$pid) {
	my $ok = 1;
	$ok = close $reader				if $ok;
	$ok = fcntl $writer, F_SETFD, 1			if $ok;
	$ok = &$code()					if $ok && $code;
	$^W = 0; # turn off "Can't exec" message
	if (!$ok or !exec @cmd) {
	    select $writer;
	    $| = 1;
	    print $!+0;
	    POSIX::_exit 1;
	}
    }
    close $writer or croak "Error closing parent's write pipe: $!";

    my ($nread, $buf);
    while (1) {
	$nread = sysread $reader, $buf, 16;
	last if defined $nread;
	next if $! == EINTR;
	croak "Error reading from pipe: $!";
    }
    close $reader or croak "Error closing parent's read pipe: $!";
    if ($nread) {
    	while (waitpid($pid, 0) == -1) {
	    next if $! == EINTR;
	    croak "Error waiting for child: $!";
	}
	$pid = undef;
	$! = $buf+0 || EINTR;
    }
    return $pid;
}

=item B<sync_fhpopen_noshell> I<fh> I<type> I<cmd> [I<arg>]...

This is a popen() but it never invokes the shell and it uses sync_exec()
under the covers.  See L</sync_exec>.

The I<type> is either C<'r'> to read from the process or C<'w'> to write
to it.

The return value is the pid of the forked process.

=cut

sub sync_fhpopen_noshell {
    @_ >= 3 or croak 'Usage: sync_fhpopen_noshell fh type cmd...';
    my $fh_parent = qualify_to_ref shift, caller;
    my ($type, @cmd) = @_;
    my ($fh_child, $fh_dup_to, $fh_dup_type, $result);

    $fh_child = gensym;
    if ($type eq 'w') {
	$result = pipe $fh_child, $fh_parent;
	$fh_dup_to = \*STDIN;
	$fh_dup_type = '<&';
    }
    elsif ($type eq 'r') {
	$result = pipe $fh_parent, $fh_child;
	$fh_dup_to = \*STDOUT;
	$fh_dup_type = '>&';
    }
    else {
	croak "Invalid popen type `$type'";
    }

    $result or croak "Can't pipe(): $!";
    $result = sync_exec sub {
		    close $fh_parent
			and open $fh_dup_to, $fh_dup_type . fileno $fh_child
			and close $fh_child
		}, @cmd;
    my $errno = $!;
    close $fh_child
	or croak "Error closing parent pipe: $!";
    $! = $errno;
    return $result;
}

=item B<sync_popen_noshell> I<type> I<cmd> I<arg>...

This is like B<sync_fhpopen_noshell>, but you don't have to supply
the filehandle.

If called in an array context the return value is a list consisting of
the filehandle and the PID of the child.  In a scalar context only the
filehandle is returned.

=cut

#'

sub sync_popen_noshell {
    @_ >= 2 or croak 'Usage: sync_popen_noshell type cmd...';
    my ($type, @cmd) = @_;
    my $fh = gensym;
    my $pid = sync_fhpopen_noshell $fh, $type, @cmd
    	or return;
    wantarray ? ($fh, $pid) : $fh;
}

=item B<sync_open> I<fh> [I<open-spec>]

This is like a Perl open() except that if a pipe is involved and the
implied exec() fails sync_open() fails with $! set appropriately.  See
L</sync_exec>.

Like B<sync_exec>, B<sync_open> croak()s if there is an unexpected
system error (such as a failed pipe()).

Also like B<sync_exec>, if you use a command which Perl needs to use the
shell to interpret you'll only know if the exec of the shell worked.
Use B<sync_fhpopen_noshell> or B<sync_exec> to be sure that this doesn't
happen.

=cut

sub sync_open {
    @_ == 1 or @_ == 2 or croak 'Usage: sync_open fh [open-spec]';
    my $fh = qualify_to_ref shift, caller;
    my $cmd = @_ ? shift : $fh;
    my $type;

    $cmd =~ s/^\s+//;
    $cmd =~ s/\s+$//;
    if ($cmd =~ s/^\|//) {
	if (substr($cmd, -1) eq '|') {
	    croak "Can't do bidirectional pipe";
	}
	$type = 'w';
    }
    elsif ($cmd =~ s/\|$//) {
	$type = 'r';
    }
    else {
	# Not a pipe, just do a regular open.
	return open $fh, $cmd;
    }
    return sync_fhpopen_noshell $fh, $type, $cmd;
}


1

__END__

=back

=head1 AUTHOR

Roderick Schertler <F<roderick@argon.org>>

=head1 SEE ALSO

perl(1).

=cut
