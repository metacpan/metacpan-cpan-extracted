######################################################################
package Proc::Short;
######################################################################
# Copyright 1999 by John Hanju Kim, all rights reserved.
#
# This program is free software, you can redistribute it and/or 
# modify it under the same terms as Perl itself.
#
# The newest version of this module is available on
# your favourite CPAN site under
#     CPAN/modules/by-author/id/JHKIM
#
######################################################################

=head1 NAME

Proc::Short -- return short system calls with options

=head1 SYNOPSIS

   use Proc::Short;

   $myproc = Proc::Short->new();  # create a new process object

   # settings below represent defaults
   $myproc->maxtime(300);         # set final timeout after 5 minutes
   $myproc->num_tries(5);         # try 5 times at most
   $myproc->time_per_try(30);     # time per try 30 sec
   $myproc->time_btw_tries(5);    # time between tries 5 sec

   # additional options
   $myproc->accept_no_error();    # Re-try if any STDERR output
   $myproc->pattern_stdout($pat); # require STDOUT to match regex $pat
   $myproc->pattern_stderr($pat); # require STDERR to match regex $pat
   $myproc->allow_shell(0);       # never use shell for operation
   $myproc->allow_shell(1);       # allowed to use shell for op

   $myproc->run("shell-command-line"); # Launch a shell process
   $myproc->run(sub { ... });          # Launch a perl subroutine
   $myproc->run(\&subroutine);         # Launch a perl subroutine

   Proc::Short::debug($level);         # Turn debug on

=head1 DESCRIPTION

The Proc::Short is intended to be an extension of the backticks 
operator in PERL which incorporates a number of options, including 
collecting STDOUT and STDERR separately -- plus timeout and 
automatic retries.  A new process object is created by

   $myproc = Proc::Short->new();

The default will timeout after 30 seconds (I<timeout>) for each 
attempt, will try a process up to 10 times, with 5 seconds 
between each try.  Either shell-like command lines or references 
to perl subroutines can be specified for launching a process in 
background.  A simple list process, for example, can be started 
via the shell as

   ($out, $in) = $myproc->run("ls");

or, as a perl subroutine, with

   $myproc->run(sub { return <*>; });

The I<run> Method will try to run the named process.  If the 
process times out (after I<time_per_try> seconds) or has a 
error defined as unacceptable, it will wait (for I<time_btw_tries> 
seconds) and try again.  This can repeat until I<maxtime> 
seconds or I<num_tries> tries of the process to be run.  

The user can specify what constitutes an unacceptable error 
of STDOUT or STDERR output -- i.e. demanding a retry.  One 
common shorthand is to have the I<run> method retry if there 
is any return from STDERR.  

   $myproc->accept_no_error();    # Re-try if any STDERR
   $myproc->pattern_stdout($pat); # require STDOUT to match regex $pat
   $myproc->pattern_stderr($pat); # require STDERR to match regex $pat

=cut

require 5.003;
use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %SIG $AUTOLOAD);

require Exporter;

@ISA     = qw(Exporter AutoLoader);
@EXPORT  = qw( );
$VERSION = '0.01';

######################################################################
# Globals: Debug and the mysterious waitpid nohang constant.
######################################################################
my $Debug = 0;
my $alarm_msg = "Proc::Short: child timed out";
my $WNOHANG = _get_system_nohang();
my %intdefaults= ( "maxtime"=>300, "num_tries"=>5, 
		   "time_per_try"=>30, "time_btw_tries"=>5, 
		   "allow_shell"=>1 );

######################################################################

=head1 METHODS

The following methods are available:

=over 4

=item new (Constructor)

Create a new instance of this class by writing either

  $proc = new Proc::Short;   or   $proc = Proc::Short->new();

The I<new> method takes no arguments.

=cut

######################################################################
# $proc_obj=Proc::Short->new(); - Constructor
######################################################################
sub new { 
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self= { %intdefaults };

  # Object parameters defining operation
  $self->{"pattern_stdout"}= undef; # required regex match on STDOUT
  $self->{"pattern_stderr"}= undef; # required regex match on STDOUT
  $self->{"allow_shell"}= 1;

  # Output fields
  $self->{"stdout"}= undef;
  $self->{"stderr"}= undef;
  $self->{"status"}= undef;

  return bless($self, $class);
}

######################################################################

=item findexec

Find where the named executables are in the path, or die if 
any are not found.  

 ($fullpath) = $proc->needexec("ssh");

The I<needexec> method ...

=cut

######################################################################
# find where named executables are
######################################################################
sub findexec {
    my $self= shift;
    my ($needed, $found); # executable name we're looking for
    my @path= split(':',$ENV{PATH});
    foreach $needed (@_) {
	foreach (@path) {
	    $_.="/$needed";
	    if (-f && -x) { 
		$found=$_; 
		last; # break out of loop over directories
	    } else {
		$found= undef;
	    }
	} # end of loop over @path directories
	$_ = $found; # set input list to found
    } # end of loop over executables needed
    return $found if ((scalar @_) == 1);
    return @_ if (wantarray());
    return scalar(@_); # return number of elements found
}
######################################################################

=item unixhelp

Try various ways to get help on a given executable.  

 ($helpmsg) = $proc->unixhelp("ssh");

=cut

######################################################################
# tries various ways to get help, and return shortest message
######################################################################
sub unixhelp {
    my ($self, $exec)= @_;
    return undef unless findexec($exec);
    # try -help, -h, -H, -hh
    my @list; 
    foreach ("help", "h", "H", "hh") {
	my ($out, $err)= run("$exec -v");
    }
    # look for "Usage:"

}
######################################################################

=item unixversion

Try various ways to get version number on a given executable.  

 ($helpmsg) = $proc->unixhelp("ssh");

=cut

######################################################################
# tries various ways to get version number
######################################################################
sub unixversion {
    my $exec= shift;
    needexec("$exec");
    # try -help -h -H -V --version -version
    my $out= run("$exec -v");

    # look for "version #.#.#" "name (...) #.#.#

}

######################################################################

=item run

Run a new process and collect the standard output and standard 
error via separate pipes.  By default, it forks off another 
process and collects the output when it is done.  There is a 
time limit of 

 ($out, $err, $status) = $proc->run("program-name");

There are a number of options.  You can start execution of an 
independent Perl function (like "eval" except with timeout, 
retries, etc.).  Simply provide the function reference like

 ($out, $err, $status) = $proc->run(\&perl_function);

or supply an unnamed subroutine:

 ($out, $err, $status) = $proc->run( sub { sleep(1) } );

The I<run> Method returns after the the function finishes, 
one way or another.  

=cut

######################################################################
# ($out, $err, $status) = $proc_obj->run("prg"); - Run process
######################################################################
sub run {
    my $self = shift;
    my $cmd = shift;

    my ($pid, $t, $out, $err, $status) = (undef) x 5;

    my $ntry= 0;
    my $starttime= time();
    my $endtime= time() + $self->maxtime();
    my $time_per_try= $self->time_per_try();

    my $patout= $self->pattern_stdout();
    my $paterr= $self->pattern_stdout();

  ATTEMPT: {
      $self->_dprt("ATTEMPT $ntry: \"$cmd\" ");

      # set up pipes to collect STDOUT and STDERR from child process
      pipe(GETSTDOUT,PUTSTDOUT);
      pipe(GETSTDERR,PUTSTDERR);
      pipe(GETSTATUS,PUTSTATUS);
      # fork starts a child process, returns 1 for parent, 0 for child
      if (($pid = fork()) == 0) { # if child process
	  $t= $endtime - time();
	  $t= $time_per_try if ($time_per_try < $t);
	  # Define procedure for when the child process times out
	  $SIG{'ALRM'} = sub { die $alarm_msg; }; 
	  eval {
	      alarm($t);
	      open(STDOUT, ">&=PUTSTDOUT") or croak 
		  "Couldn't redirect STDOUT: $!";
	      $|= 1; # forces autoflushing of buffer
	      open(STDERR, ">&=PUTSTDERR") or croak 
		  "Couldn't redirect STDERR: $!";
	      $|= 1;
	      close(GETSTDOUT); close(GETSTDERR); close(GETSTATUS);
	      if(ref($cmd) eq "CODE") {
		  $status= &$cmd;           # Start perl subroutine
	      } else {
		  $status= system($cmd);    # Start Shell-Process
	      }
	      print PUTSTATUS $status;
	      exit; # end of child process
	  } # end of eval
      } # end of fork block

      # as parent, wait for child to finish
      if (defined $WNOHANG) {
	  while (waitpid(-1, $WNOHANG) > 0) { 1; }
      } else { 
	  wait();
      }
      # continue with parent process procedure
      close(PUTSTDOUT); close(PUTSTDERR); close(PUTSTATUS);
      while (<GETSTDOUT>) { $out .= $_; }
      while (<GETSTDERR>) { $err .= $_; }
      while (<GETSTATUS>) { $status .= $_; }
      close(GETSTDOUT); close(GETSTDERR); close(GETSTATUS);

      # Now try to figure out if anything went wrong
      $ntry++;
      my $redo= 0;
      if ($@ =~ /$alarm_msg\s*$/) {
	  $err .= "Timed out after $t seconds\n";
	  $redo++;
      } elsif ((not defined($pid)) and ($! =~ /No more process/)) {
	  $err .= "PERL fork error: $!\n";
	  $redo++;
      } elsif (not defined($pid)) {
	  $err .= "PERL fork error: $!\n"; 
	  $redo++;
      } elsif (defined($patout) or defined($paterr)) {
	  $redo++ unless ($out =~ /$patout/);
	  $redo++ unless ($err =~ /$paterr/);
      }
      $self->_dprt("STDOUT\n$out");
      $self->_dprt("STDERR\n$err");
      $self->_dprt("RETURNVALUE $status");
      if (($ntry < $self->num_tries) or (time() < $endtime)) { 
	  $err .= "Final attempt after $ntry tries and $t seconds\n";
      } elsif ($redo) {
	  sleep $self->time_btw_tries;
	  redo ATTEMPT;
      }
  } # end of ATTEMPT block
    return $out unless (wantarray());
    return ($out, $err, $status);
}

######################################################################
=item debug

Switches debug messages on and off -- Proc::Short::debug(1) switches
them on, Proc::Short::debug(0) keeps Proc::Short quiet.

=cut

sub debug { $Debug = shift; } # debug($level) - Turn debug on/off

######################################################################
=item accept_no_error

Switches debug messages on and off -- Proc::Short::debug(1) switches
them on, Proc::Short::debug(0) keeps Proc::Short quiet.

=cut

sub debug { $Debug = shift; } # debug($level) - Turn debug on/off


######################################################################
=item maxtime
Return or set the maximum time in seconds per I<run> method call.  
Default is 300 seconds (i.e. 5 minutes). 
=cut

=item num_tries
Return or set the maximum number of tries the I<run> method will 
attempt an operation if there are unallowed errors.  Default is 5. 
=cut

=item time_per_try
Return or set the maximum time in seconds for each attempt which 
I<run> makes of an operation.  Multiple tries in case of error 
can go longer than this.  Default is 30 seconds. 
=cut

=item time_btw_tries
Return or set the time in seconds between attempted operations 
in case of unacceptable error.  Default is 5 seconds.  
=cut

sub AUTOLOAD {
    my $self= shift; 
    my $type= ref($self) or croak("$self is not an object");
    my $name= $AUTOLOAD; 
    $name =~ s/.*://; # strip qualified call, i.e. Geometry::that
    unless (exists $self->{$name}) {
	croak("Can't access `$name' field in object of class $type");
    }
    if (@_) {
	my $val= @_;
	if (defined($intdefaults{$name}) and not ($val =~ /\d+/)) {
	    croak "Invalid $name initializer $val";
	}
	$self->{$name}= $val;
    }
    return $self->{$name};
}

######################################################################
# Internal debug print function
######################################################################
sub _dprt { 
    return unless $Debug;
    if (ref($_[0])) {
        warn ref(shift()), "> @_\n"; 
    } else {
	warn "> @_\n";
    }
}

######################################################################
# This is for getting the WNOHANG constant of the system: a magic 
# flag for the "waitpid" command which guards against certain errors
# which could hang the system.  
# 
# Since the waitpid(-1, &WNOHANG) command isn't supported on all Unix 
# systems, and we still want Proc::Short to run on every system, we 
# have to quietly perform some tests to figure out if -- or if not.
# The function returns the constant, or undef if it's not available.
######################################################################
sub _get_system_nohang {
    my $nohang;
    open(SAVEERR, ">&STDERR");
    # If the system doesn't even know /dev/null, forget about it.
    open(STDERR, ">/dev/null") || return undef;
    # Close stderr, since some weirdo POSIX modules write nasty
    # error messages
    close(STDERR);
    # Check for the constant
    eval 'use POSIX ":sys_wait_h"; $nohang = &WNOHANG;';
    # Re-open STDERR
    open(STDERR, ">&SAVEERR");
    close(SAVEERR);
    # If there was an error, return undef
    return undef if $@;
    return $nohang;
}

1;

__END__

=head1 NOTE

This is an attempt to duplicate the ease of use of backticks (``) 
while allowing additional options like timeout or re-tries in 
case of error.  

=head1 Requirements

I'd recommend using at least perl 5.003 -- if you don't have 
it, this is the time to upgrade! Get 5.005_02 or better.

=head1 AUTHORS

John Hanju Kim <jhkim@fnal.gov>

=cut

