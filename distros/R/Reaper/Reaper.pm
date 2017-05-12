# -*-perl-*-
###########################################################################
=pod

=head1 NAME

Reaper - support for reaping child processes via $SIG{CHLD}

=head1 SYNOPSIS

  use Reaper qw( reaper reapPid pidStatus );

  my $pid = fork;
  if ( $pid == 0 ) { # child
    exec $some_command;
  }
  reapPid ( $pid );

  ...

  if ( defined(my $exit = pidStatus($pid)) ) {
    # child exited, check the code...
  }


=head1 DESCRIPTION

perl has an annoying little problem with child processes -- well, it
is not actually a problem specific to perl, but it is somewhat more
difficult with perl: reaping child processes after they exit so they
don't hang around as zombies forever, and doing it in a way that
accurately captures the exit code of the child.

The right way to do it is to install a $SIG{CHLD} handler which calls
waitpid to reap the child process and store $? at that point.  But the
problem is that different modules may step on each other in installing
their own version of the handler, there's no uniform way of doing this.

For some situations, a local $SIG{CHLD} handler is sufficient, but
often times the handler is no longer in scope at the time the child
process exits -- since the child may exit at any time.  The local
handler is dynamically scoped, not lexically, so it depends entirely
on what subroutine is being executed at the time the signal is caught.

So the Reaper module provides a $SIG{CHLD} handler that can be
installed globally as well as locally.  It also supports chaining of
signal handlers, meaning it will not just replace an existing
$SIG{CHLD} handler.  It still requires applications to do the right
thing in using this module and not installing their own versions.  At
least it provides a consistent implementation that can be shared
between various modules.

=head1 FUNCTIONS IN DETAIL

=over 4

=cut
#'
###########################################################################

use 5.006;

use strict;

package Reaper;
use base qw( Exporter );

use POSIX ":sys_wait_h";


use vars qw( $VERSION );
$VERSION = '1.00';


# Auto-exported symbols:
@Reaper::EXPORT = qw( );

# Caller must request these ones:
@Reaper::EXPORT_OK = qw( reaper reapPid pidStatus );

# Hash to track what processes have been registered for reaping.
my %REAP_PIDS = ();

# Hash to store exit status from children
# Lexically scoped so it must be accessed via pidStatus()
my %PID_STATUS = ();


sub _storePidStatus ($$)
{
  my ($pid, $status) = @_;
  delete $REAP_PIDS{$pid};
  $PID_STATUS{$pid} = $status;
}


######################################################################
# Subroutine installed as the actual $SIG{CHLD} handler.
#
# Will only wait on processes registered via reapPid().
# Other $SIG{CHLD} handlers may also have been installed,
# in which case we must chain to them so they can wait on the required
# processes.
# For this mechanism to work, any handlers installed after this one
# must also chain to this handler, and must not steal the status
# of the children this one is trying to monitor, i.e. don't do this:
#
#    do { $kid = waitpid ( -1, WNOHANG ); } until $kid == -1;
#
#
######################################################################
my $chaining = 0;
sub REAPER
{
  my ($sig, $chain) = @_;

  return if ( $chaining ); # Prevent infinite recursion

  # Standard mode is to only wait for requested pids, otherwise we
  # still the exit status from another $SIG{CHLD} handler.
  if ( my @pids = keys %REAP_PIDS ) {
    foreach my $pid ( @pids ) {
      my $pidwait = waitpid ( $pid, WNOHANG );
      if ( defined($pidwait) && $pidwait == $pid ) {
	_storePidStatus ( $pid => $? );
      }
    }
  }
	
  # Chain to the next handler, if any...
  if ( defined($chain) && ref($chain) eq 'CODE' ) {
    local $@;
    $chaining = 1;
    eval { $chain-> ( $sig ); };
    $chaining = 0;
    if ( $@ ) {
      print STDERR ( "(in reaper) $@\n" );
    }
  }

  # Must reinstall each time...
  #$SIG{CHLD} = sub { Reaper::REAPER ( shift, $chain ); };

  1;
}


######################################################################
=pod

=item * reaper BLOCK

Install a local $SIG{CHLD} handler for a block of code, e.g.:

   reaper {
     do_something();
     ...
   };

Any children that exit while the block is being executed (whether
started within that block or not) will cause the local $SIG{CHLD} to
be executed.  The child exit status will be saved, and will be
available via the pidStatus() call.

=cut
######################################################################
sub reaper (&)
{
  my $block = shift;
  my $chain = $SIG{CHLD};
  local $SIG{CHLD} = sub { Reaper::REAPER ( shift, $chain ); };
  $block->();
}


######################################################################
=pod

=item * reapPid PIDLIST

Register one or more PIDs to be reaped.  The reaper will only try
to reap PIDs that have been registered, so that it does not steal
the exit status for a pid from another handler.

=cut
######################################################################
sub reapPid (@)
{
  my (@pids) = @_;

  foreach my $pid ( @pids ) {
    my $r = ref($pid);
    if ( defined($r) ) {
      local $@;
      eval {
	# special cases for @pids passed as references.
	if ( $r =~ /^IO::Pipe/ ) {
	  $pid = ${*$pid}{'io_pipe_pid'}; # See IO/Pipe.pm
	}
	else { $pid = undef; }
      };
      if ( $@ ) { $pid = undef; };
    }

    if ( defined($pid) && $pid > 0 ) {
      $REAP_PIDS{$pid} = 1;
    }
  }
  1;
}


######################################################################
=pod

=item * pidStatus PID

Return the exit status of a specific PID.  If no status for the PID is
available (i.e. the process is still running), returns undef.

=cut
######################################################################
sub pidStatus ($)
{
  my $pid = shift;

  return $PID_STATUS{$pid} if exists $PID_STATUS{$pid};

  my $pidwait = waitpid ( $pid, WNOHANG );
  if ( defined($pidwait) && $pidwait == $pid ) {
    return _storePidStatus ( $pid => $? );
  }

  return undef;
}


######################################################################
# automatically install REAPER
# as the global handler
######################################################################
$SIG{CHLD} = sub { Reaper::REAPER ( shift, $SIG{CHLD} ); };



###########################################################################
# End of package
###########################################################################
package main;
1;
__END__
=pod

=back

=head1 AUTHOR

Jeremy Slade E<lt>jeremy@jkslade.netE<gt>


=cut

