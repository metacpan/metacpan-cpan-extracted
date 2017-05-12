package System2;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use POSIX qw(:sys_wait_h :limits_h);
use Fcntl;
use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( &system2 );
$VERSION = '0.84';

use vars qw/ $debug /;

# set to nonzero for diagnostics.
$debug=0;

#---------------------------------

my @handle = qw(C_OUT C_ERR);
my $sigchld; # previous SIGCHLD handler
my @args;
my %buf = ();
my %fn = ();
my ($rin, $win, $ein);
my ($rout, $wout, $eout);
my $pid;

my $path;

#---------------------------------
sub system2
{
  @args = @_;

  # fake named parameters
  my $named_param_check=0;
  if ( $#args % 2 )
  {
    my %param = @args;
    # look for arg0 path args
    if ((exists $param{'args'}) && ( ref ($param{'args'}) eq 'ARRAY') )
    {
      @args = @{$param{'args'}};
      $path = $param{'path'};
      unshift @args, exists $param{'arg0'} ? $param{'arg0'} : $path;
      $named_param_check++;
    }
  }

  # if we didn't find useful named parameters, treat as the legacy interface
  if (! $named_param_check)
  {
    if (ref($args[0]) eq 'ARRAY')
    {
      my $arg0;
      ($path, $arg0) = @{ shift @args };
      unshift @args, $arg0;
    } else { $path = $args[0]; }
  }

  # set up handles to talk to forked process
  pipe(P_IN, C_IN) || croak "can't pipe IN: $!";
  pipe(C_OUT, P_OUT) || croak "can't pipe OUT: $!";
  pipe(C_ERR, P_ERR) || croak "can't pipe ERR: $!";

  # prep filehandles.  get file numbers, set to non-blocking.

  ($rin, $win, $ein) = ('') x 3;
  ($rout, $wout, $eout) = ('') x 3;
  no strict 'refs';
  foreach( @handle )
  {
    # set to non-blocking
    my $ret=0;
    fcntl($_, F_GETFL, $ret) || croak "can't fcntl F_GETFL $_";
    $ret |= O_NONBLOCK;
    fcntl($_, F_SETFL, $ret) || croak "can't fcntl F_SETFL $_";

    # prep fd masks for select()
    $fn{$_} = fileno($_);
    vec($rin, $fn{$_}, 1) = 1;
    $buf{$fn{$_}} = '';
  }
  use strict 'refs';

  $debug && carp "fork/exec: [$path] [".join('] [', @args)."]";

  # temporarily disable SIGCHLD handler
  $sigchld = (defined $SIG{'CHLD'}) ? $SIG{'CHLD'} : 'DEFAULT';
  $SIG{'CHLD'} = 'DEFAULT';

  $pid = fork();
  croak "can't fork [@args]: $!" unless defined $pid;

  &child if (!$pid); # child
  my @res = &parent; # parent

  $SIG{'CHLD'} = $sigchld; # restore SIGCHLD handler

  @res; # return output from child process
}

#---------------------------------

sub child
{
  $debug && carp "child pid: $$";

  # close unneeded handles, dup as necessary.
  close C_IN || croak "child: can't close IN: $!";
  close C_OUT || croak "child: can't close OUT: $!";
  close C_ERR || croak "child: can't close ERR: $!";

  open(STDOUT, '>&P_OUT') || croak "child: can't dup STDOUT: $!";
  open(STDERR, '>&P_ERR') || croak "child: can't dup STDERR: $!";

  select C_OUT; $|=1;
  select C_ERR; $|=1;

  # from perldiag(1):
  #  Statement unlikely to be reached
  #      (W) You did an exec() with some statement after it
  #      other than a die().  This is almost always an error,
  #      because exec() never returns unless there was a
  #      failure.  You probably wanted to use system() instead,
  #      which does return.  To suppress this warning, put the
  #      exec() in a block by itself.

  { exec { $path } @args; }

  croak "can't exec [$path] [".join('] [', @args)."]: $!";
}

#---------------------------------

# parent

sub parent
{
  # close unneeded handles
  close P_IN || croak "can't close IN: $!";
  close P_OUT || croak "can't close OUT: $!";
  close P_ERR || croak "can't close ERR: $!";

  # default exit status of child (we fail unless we succeed)
  my $status = (1<<8);

  # get data from filehandles, append to appropriate buffers.
  my $nfound = 0;
  while ($nfound != -1)
  {
    $nfound = select($rout=$rin, $wout=$win, $eout=$ein, 1.0);
    if ($nfound == -1) { carp "select() said $!\n"; last }

    no strict 'refs';
    foreach( @handle )
    {
      if (vec($rout, $fn{$_}, 1))
      {
        my $read;
        my $len = length($buf{$fn{$_}});
        my $FD = $fn{$_};

        while ($read = sysread ($_, $buf{$FD}, PIPE_BUF, $len))
        {
          if (!defined $read) { carp "read() said $!\n"; last }
          if ($read == 0) { carp "read() said eof\n"; last }
          $len += $read;
          $debug && carp "read $read from $_ (len $len)";
        }
      }
    }
    use strict 'refs';

    # check for dead child

    # pid of exiting child; the waitpid returns -1 if
    # we waitpid again...
    my $child = waitpid($pid, WNOHANG);

    last if ($child == -1); # child already exited
    #next unless $child;     # no stopped or exited children

    # Is it possible for me to have data in a buffer after the
    # child has exited?  Yep...

    $status = $?;
  }

  $? = $status; # exit with child's status

  ($buf{$fn{'C_OUT'}}, $buf{$fn{'C_ERR'}});
}

#---------------------------------
sub exit_status
{
  my $s = shift;

  my $exit_value  = $s >> 8;
  my $signal_num  = $s & 127;
  my $dumped_core = $s & 128;

  ($exit_value, $signal_num, $dumped_core);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

System2 - like system(), but with access to STDOUT and STDERR.

=head1 SYNOPSIS

  use System2;

  $System2::debug++;

  my ($out, $err) = system2(@args);

  my ($exit_value, $signal_num, $dumped_core) = &System2::exit_status($?);
  
  print "EXIT: exit_value $exit_value signal_num ".
        "$signal_num dumped_core $dumped_core\n";
  
  print "OUT:\n$out";
  print "ERR:\n$err"

=head1 DESCRIPTION

The module presents an interface for executing a command, and
gathering the output from STDOUT and STDERR.

Benefits of this interface:

=over 2

=item -

the Bourne shell is never implicitly invoked: saves a stray exec(),
and bypasses those nasty shell quoting problems.

=item -

cheaper to run than open3().

=item -

augmented processing of arguments, to allow for overriding arg[0]
(eg. initiating a login shell).

=back

STDOUT and STDERR are returned in scalars.  $? is set.  (Split on
$/ if you want the expected lines back.)

If $debug is set, on-the fly diagnostics will be reported about
how much data is being read.

Provides for convenience, a routine exit_status() to break out the
exit value into separate scalars, straight from perlvar(1):

=over 2

=item -

the exit value of the subprocess

=item -

which signal, if any, the process died from

=item -

reports whether there was a core dump.

=back

There are two interfaces available:  a regular list, or named
parameters:

These are equivalent:

  my @args = ( '/bin/sh', '-x', '-c', 'echo $0' );

  my @args = ( path => '/bin/sh', args => [ '-c', 'echo $0' ] );

To override arg[0], pass in a arrayref for the first argument, or
use the arg0 named parameter.  Contrast the prior argument lists
with these below:

  my @args = ( ['/bin/sh', '-sh'], '-c', 'echo $0' );

  my @args = ( path => '/bin/sh', args => ['-c', 'echo $0'],
               arg0 => '-sh' );

=head1 CAVEATS

Obviously, the returned scalars can be quite large, depending on
the nature of the program being run.  In the future, I intend to
introduce options to allow for temporary file handles, but for now,
be aware of the potential resource usage.

Although I've been using this module for literally years now
personally, consider it lightly tested, until I get feedback from
the public at large.  (Treat this as a hint to tell me that you're
using it. :)

Have at it.

=head1 AUTHOR

Brian Reichert <reichert@numachi.com>

=head1 SEE ALSO

perlfunc(1), perlvar(1).

=cut
