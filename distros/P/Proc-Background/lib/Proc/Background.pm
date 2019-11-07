package Proc::Background;
$Proc::Background::VERSION = '1.21';
# ABSTRACT: Generic interface to background process management
require 5.004_04;

use strict;
use Exporter;
use Carp;
use Cwd;
use Scalar::Util;
@Proc::Background::ISA       = qw(Exporter);
@Proc::Background::EXPORT_OK = qw(timeout_system);

# Determine if the operating system is Windows.
my $is_windows = $^O eq 'MSWin32';
my $weaken_subref = Scalar::Util->can('weaken');

# Set up a regular expression that tests if the path is absolute and
# if it has a directory separator in it.  Also create a list of file
# extensions of append to the programs name to look for the real
# executable.
my $is_absolute_re;
my $has_dir_element_re;
my $path_sep;
my @extensions = ('');
if ($is_windows) {
  $is_absolute_re     = '^(?:(?:[a-zA-Z]:[\\\\/])|(?:[\\\\/]{2}\w+[\\\\/]))';
  $has_dir_element_re = "[\\\\/]";
  $path_sep           = "\\";
  push(@extensions, '.exe');
} else {
  $is_absolute_re     = "^/";
  $has_dir_element_re = "/";
  $path_sep           = "/";
}

# Make this class a subclass of Proc::Win32 or Proc::Unix.  Any
# unresolved method calls will go to either of these classes.
if ($is_windows) {
  require Proc::Background::Win32;
  unshift(@Proc::Background::ISA, 'Proc::Background::Win32');
} else {
  require Proc::Background::Unix;
  unshift(@Proc::Background::ISA, 'Proc::Background::Unix');
}

# Take either a relative or absolute path to a command and make it an
# absolute path.
sub _resolve_path {
  my $command = shift;

  return unless length $command;

  # Make the path to the progam absolute if it isn't already.  If the
  # path is not absolute and if the path contains a directory element
  # separator, then only prepend the current working to it.  If the
  # path is not absolute, then look through the PATH environment to
  # find the executable.  In all cases, look for the programs with any
  # extensions added to the original path name.
  my $path;
  if ($command =~ /$is_absolute_re/o) {
    foreach my $ext (@extensions) {
      my $p = "$command$ext";
      if (-f $p and -x _) {
        $path = $p;
        last;
      }
    }
    unless (defined $path) {
      warn "$0: no executable program located at $command\n";
    }
  } else {
    my $cwd = cwd;
    if ($command =~ /$has_dir_element_re/o) {
      my $p1 = "$cwd$path_sep$command";
      foreach my $ext (@extensions) {
        my $p2 = "$p1$ext";
        if (-f $p2 and -x _) {
          $path = $p2;
          last;
        }
      }
    } else {
      foreach my $dir (split($is_windows ? ';' : ':', $ENV{PATH})) {
        next unless length $dir;
        $dir = "$cwd$path_sep$dir" unless $dir =~ /$is_absolute_re/o;
        my $p1 = "$dir$path_sep$command";
        foreach my $ext (@extensions) {
          my $p2 = "$p1$ext";
          if (-f $p2 and -x _) {
            $path = $p2;
            last;
          }
        }
        last if defined $path;
      }
    }
    unless (defined $path) {
      warn "$0: cannot find absolute location of $command\n";
    }
  }

  $path;
}

# We want the created object to live in Proc::Background instead of
# the OS specific class so that generic method calls can be used.
sub new {
  my $class = shift;

  my $options;
  if (@_ and defined $_[0] and UNIVERSAL::isa($_[0], 'HASH')) {
    $options = shift;
  }

  unless (@_ > 0) {
    confess "Proc::Background::new called with insufficient number of arguments";
  }

  return unless defined $_[0];

  my $self = $class->SUPER::_new(@_) or return;

  # Save the start time of the class.
  $self->{_start_time} = time;

  # Handle the specific options.
  if ($options) {
    if ($options->{die_upon_destroy}) {
      $self->{_die_upon_destroy} = 1;
      # Global destruction can break this feature, because there are no guarantees
      # on which order object destructors are called.  In order to avoid that, need
      # to run all the ->die methods during END{}, and that requires weak
      # references which weren't available until 5.8
      $weaken_subref->( $Proc::Background::_die_upon_destroy{$self+0}= $self )
        if $weaken_subref;
      # could warn about it for earlier perl... but has been broken for 15 years and
      # who is still using < 5.8 anyway?
    }
  }

  bless $self, $class;
}

sub DESTROY {
  my $self = shift;
  if ($self->{_die_upon_destroy}) {
    # During a mainline exit() $? is the prospective exit code from the
    # parent program. Preserve it across any waitpid() in die()
    local $?;
    $self->die;
    delete $Proc::Background::_die_upon_destroy{$self+0};
  }
}

END {
  # Child processes need killed before global destruction, else the
  # Win32::Process objects might get destroyed first.
  $_->die for grep defined, values %Proc::Background::_die_upon_destroy;
  %Proc::Background::_die_upon_destroy= ();
}

# Reap the child.  If the first argument is false, then return immediately.
# Else, block waiting for the process to exit.  If no second argument is
# given, wait forever, else wait for that number of seconds.
# If the wait was sucessful, then delete
# $self->{_os_obj} and set $self->{_exit_value} to the OS specific
# class return of _reap.  Return 1 if we sucessfully waited, 0
# otherwise.
sub _reap {
  my ($self, $blocking, $wait_seconds) = @_;

  return 0 unless exists($self->{_os_obj});

  # Try to wait on the process.  Use the OS dependent wait call using
  # the Proc::Background::*::waitpid call, which returns one of three
  # values.
  #   (0, exit_value)	: sucessfully waited on.
  #   (1, undef)	: process already reaped and exit value lost.
  #   (2, undef)	: process still running.
  my ($result, $exit_value) = $self->_waitpid($blocking, $wait_seconds);
  if ($result == 0 or $result == 1) {
    $self->{_exit_value} = defined($exit_value) ? $exit_value : 0;
    delete $self->{_os_obj};
    # Save the end time of the class.
    $self->{_end_time} = time;
    return 1;
  }
  return 0;
}

sub alive {
  my $self = shift;

  # If $self->{_os_obj} is not set, then the process is definitely
  # not running.
  return 0 unless exists($self->{_os_obj});

  # If $self->{_exit_value} is set, then the process has already finished.
  return 0 if exists($self->{_exit_value});

  # Try to reap the child.  If it doesn't reap, then it's alive.
  !$self->_reap(0);
}

sub wait {
  my ($self, $timeout_seconds) = @_;

  # If $self->{_exit_value} exists, then we already waited.
  return $self->{_exit_value} if exists($self->{_exit_value});

  # If neither _os_obj or _exit_value are set, then something is wrong.
  return undef if !exists($self->{_os_obj});

  # Otherwise, wait for the process to finish.
  return $self->_reap(1, $timeout_seconds)? $self->{_exit_value} : undef;
}

sub die {
  my $self = shift;

  # See if the process has already died.
  return 1 unless $self->alive;

  croak '->die(@kill_sequence) should have an even number of arguments'
    if @_ & 1;
  # Kill the process using the OS specific method.
  $self->_die(@_? ([ @_ ]) : ());

  # See if the process is still alive.
  !$self->alive;
}

sub start_time {
  $_[0]->{_start_time};
}

sub exit_code {
  return undef unless exists $_[0]->{_exit_value};
  return $_[0]->{_exit_value} >> 8;
}

sub exit_signal {
  return undef unless exists $_[0]->{_exit_value};
  return $_[0]->{_exit_value} & 127;
}

sub end_time {
  $_[0]->{_end_time};
}

sub pid {
  $_[0]->{_pid};
}

sub timeout_system {
  unless (@_ > 1) {
    confess "$0: timeout_system passed too few arguments.\n";
  }

  my $timeout = shift;
  unless ($timeout =~ /^\d+(?:\.\d*)?$/ or $timeout =~ /^\.\d+$/) {
    confess "$0: timeout_system passed a non-positive number first argument.\n";
  }

  my $proc = Proc::Background->new(@_) or return;
  my $end_time = $proc->start_time + $timeout;
  my $delay;
  while (($delay= ($end_time - time)) > 0 && !defined $proc->exit_code) {
    $proc->wait($delay);
  }

  my $alive = $proc->alive;
  $proc->die if $alive;

  if (wantarray) {
    return ($proc->wait, $alive);
  } else {
    return $proc->wait;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::Background - Generic interface to background process management

=head1 VERSION

version 1.21

=head1 SYNOPSIS

    use Proc::Background;
    timeout_system($seconds, $command, $arg1);
    timeout_system($seconds, "$command $arg1");

    my $proc1 = Proc::Background->new($command, $arg1, $arg2);
    my $proc2 = Proc::Background->new("$command $arg1 1>&2");
    $proc1->alive;
    $proc1->die;
    $proc1->wait;
    my $time1 = $proc1->start_time;
    my $time2 = $proc1->end_time;

    # Add an option to kill the process with die when the variable is
    # DESTROYed.
    my $opts  = {'die_upon_destroy' => 1};
    my $proc3 = Proc::Background->new($opts, $command, $arg1, $arg2);
    $proc3    = undef;

=head1 DESCRIPTION

This is a generic interface for placing processes in the background on
both Unix and Win32 platforms.  This module lets you start, kill, wait
on, retrieve exit values, and see if background processes still exist.

=head1 NAME

Proc::Background - Generic interface to Unix and Win32 background process management

=head1 METHODS

=over 4

=item B<new> [options] I<command>, [I<arg>, [I<arg>, ...]]

=item B<new> [options] 'I<command> [I<arg> [I<arg> ...]]'

This creates a new background process.  As exec() or system() may be
passed an array with a single single string element containing a
command to be passed to the shell or an array with more than one
element to be run without calling the shell, B<new> has the same
behavior.

In certain cases B<new> will attempt to find I<command> on the system
and fail if it cannot be found.

For Win32 operating systems:

    The Win32::Process module is always used to spawn background
    processes on the Win32 platform.  This module always takes a
    single string argument containing the executable's name and
    any option arguments.  In addition, it requires that the
    absolute path to the executable is also passed to it.  If
    only a single argument is passed to new, then it is split on
    whitespace into an array and the first element of the split
    array is used at the executable's name.  If multiple
    arguments are passed to new, then the first element is used
    as the executable's name.

    If the executable's name is an absolute path, then new
    checks to see if the executable exists in the given location
    or fails otherwise.  If the executable's name is not
    absolute, then the executable is searched for using the PATH
    environmental variable.  The input executable name is always
    replaced with the absolute path determined by this process.

    In addition, when searching for the executable, the
    executable is searched for using the unchanged executable
    name and if that is not found, then it is checked by
    appending `.exe' to the name in case the name was passed
    without the `.exe' suffix.

    Finally, the argument array is placed back into a single
    string and passed to Win32::Process::Create.

For non-Win32 operating systems, such as Unix:

    If more than one argument is passed to new, then new
    assumes that the command will not be passed through the
    shell and the first argument is the executable's relative
    or absolute path.  If the first argument is an absolute
    path, then it is checked to see if it exists and can be
    run, otherwise new fails.  If the path is not absolute,
    then the PATH environmental variable is checked to see if
    the executable can be found.  If the executable cannot be
    found, then new fails.  These steps are taking to prevent
    exec() from failing after an fork() without the caller of
    new knowing that something failed.

The first argument to B<new> I<options> may be a reference to a hash
which contains key/value pairs to modify Proc::Background's behavior.
Currently the only key understood by B<new> is I<die_upon_destroy>.
When this value is set to true, then when the Proc::Background object
is being DESTROY'ed for any reason (i.e. the variable goes out of
scope) the process is killed via the die() method.

If anything fails, then new returns an empty list in a list context,
an undefined value in a scalar context, or nothing in a void context.

=item B<pid>

Returns the process ID of the created process.  This value is saved
even if the process has already finished.

=item B<alive>

Return 1 if the process is still active, 0 otherwise.

=item B<die>, B<die(@kill_sequence)>

Reliably try to kill the process.  Returns 1 if the process no longer
exists once B<die> has completed, 0 otherwise.  This will also return
1 if the process has already died.

C<@kill_sequence> is a list of actions and seconds-to-wait for that
action to end the process.  The default is C< TERM 2 TERM 8 KILL 3 KILL 7 >.
On Unix this sends SIGTERM and SIGKILL; on Windows it just calls
TerminateProcess (graceful termination is still a TODO).

Note that C<die()> on Proc::Background 1.10 and earlier on Unix called a
sequence of:

  ->die( ( HUP => 1 )x5, ( QUIT => 1 )x5, ( INT => 1 )x5, ( KILL => 1 )x5 );

which didn't particularly make a lot of sense, since SIGHUP is open to
interpretation, and QUIT is almost always immediately fatal and generates
an unneeded coredump.  The new default should accomodate programs that
acknowledge a second SIGTERM, and give enough time for it to exit on a laggy
system while still not holding up the main script too much.

=item B<wait>

  $exit= $proc->wait; # blocks forever
  $exit= $proc->wait($timeout_seconds); # since version 1.20

Wait for the process to exit.  Return the exit status of the command
as returned by wait() on the system.  To get the actual exit value,
divide by 256 or right bit shift by 8, regardless of the operating
system being used.  If the process never existed, this returns undef.
This function may be called multiple times even after the process has
exited and it will return the same exit status.

Since version 1.20, you may pass an optional argument of the number of
seconds to wait for the process to exit.  This may be fractional, and
if it is zero then the wait will be non-blocking.  Note that on Unix
this is implemented with L<Time::HiRes/alarm> before a call to wait(),
so it may not be compatible with scripts that use alarm() for other
purposes, or systems/perls that resume system calls after a signal.
In the event of a timeout, the return will be undef.

=item B<exit_code>

Returns the exit code of the process, assuming it exited cleanly.
Returns C<undef> if the process has not exited yet, and 0 if the
process exited with a signal (or TerminateProcess).  Since 0 is
ambiguous, check for C<exit_signal> first.

=item B<exit_signal>

Returns the value of the signal the process exited with, assuming it
died on a signal.  Returns C<undef> if it has not exited yet, and 0
if it did not die to a signal.

=item B<start_time>

Return the value that the Perl function time() returned when the
process was started.

=item B<end_time>

Return the value that the Perl function time() returned when the exit
status was obtained from the process.

=back

=head1 FUNCTIONS

=over 4

=item B<timeout_system> I<timeout>, I<command>, [I<arg>, [I<arg>...]]

=item B<timeout_system> 'I<timeout> I<command> [I<arg> [I<arg>...]]'

Run a command for I<timeout> seconds and if the process did not exit,
then kill it.  While the timeout is implemented using sleep(), this
function makes sure that the full I<timeout> is reached before killing
the process.  B<timeout_system> does not wait for the complete
I<timeout> number of seconds before checking if the process has
exited.  Rather, it sleeps repeatidly for 1 second and checks to see
if the process still exists.

In a scalar context, B<timeout_system> returns the exit status from
the process.  In an array context, B<timeout_system> returns a two
element array, where the first element is the exist status from the
process and the second is set to 1 if the process was killed by
B<timeout_system> or 0 if the process exited by itself.

The exit status is the value returned from the wait() call.  If the
process was killed, then the return value will include the killing of
it.  To get the actual exit value, divide by 256.

If something failed in the creation of the process, the subroutine
returns an empty list in a list context, an undefined value in a
scalar context, or nothing in a void context.

=back

=head1 IMPLEMENTATION

I<Proc::Background> comes with two modules, I<Proc::Background::Unix>
and I<Proc::Background::Win32>.  Currently, on Unix platforms
I<Proc::Background> uses the I<Proc::Background::Unix> class and on
Win32 platforms it uses I<Proc::Background::Win32>, which makes use of
I<Win32::Process>.

The I<Proc::Background> assigns to @ISA either
I<Proc::Background::Unix> or I<Proc::Background::Win32>, which does
the OS dependent work.  The OS independent work is done in
I<Proc::Background>.

Proc::Background uses two variables to keep track of the process.
$self->{_os_obj} contains the operating system object to reference the
process.  On a Unix systems this is the process id (pid).  On Win32,
it is an object returned from the I<Win32::Process> class.  When
$self->{_os_obj} exists, then the process is running.  When the
process dies, this is recorded by deleting $self->{_os_obj} and saving
the exit value $self->{_exit_value}.

Anytime I<alive> is called, a waitpid() is called on the process and
the return status, if any, is gathered and saved for a call to
I<wait>.  This module does not install a signal handler for SIGCHLD.
If for some reason, the user has installed a signal handler for
SIGCHLD, then, then when this module calls waitpid(), the failure will
be noticed and taken as the exited child, but it won't be able to
gather the exit status.  In this case, the exit status will be set to
0.

=head1 SEE ALSO

=over

=item L<IPC::Run>

IPC::Run is a much more complete solution for running child processes.
It handles dozens of forms of redirection and pipe pumping, and should
probably be your first stop for any complex needs.

However, also note the very large and slightly alarming list of
limitations it lists for Win32.  Proc::Background is a much simpler design
and should be more reliable for simple needs.

=item L<Win32::ShellQuote>

If you are running on Win32, this article by helps describe the problem you
are up against for passing argument lists:

L<Everyone quotes command line arguments the wrong way|https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way/>
by Daniel Colascione.

This module gives you parsing / quoting per the standard
CommandLineToArgvW behavior.  But, if you need to pass arguments to be
processed by C<cmd.exe> then you need to do additional work.

=back

=head1 AUTHORS

=over 4

=item *

Blair Zajac <blair@orcaware.com>

=item *

Michael Conrad <mike@nrdvana.net>

=back

=head1 CONTRIBUTORS

=for stopwords Florian Schlichting Kevin Ryde Salvador Fandiño

=over 4

=item *

Florian Schlichting <fsfs@debian.org>

=item *

Kevin Ryde <user42@zip.com.au>

=item *

Salvador Fandiño <sfandino@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad, (C) 1998-2009 by Blair Zajac.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
