package Sys::Trace::Impl::Truss;
use strict;

use Cwd ();
use File::Spec ();
use File::Temp ();
use POSIX ();
use Text::Balanced qw(extract_quotelike extract_bracketed);
use Time::HiRes qw(time);

=head1 NAME

Sys::Trace::Impl::Truss - Sys::Trace implementation for truss(1)

=head1 DESCRIPTION

This should not normally be used directly, instead use L<Sys::Trace> which will
pick a suitable interface for your platform.

Truss is found on SVR4 systems. On Solaris in the C<SUNWtoo> package. On AIX in
C<bos.sysmgt.serv_aid> (apparently, I don't have access to AIX, hopefully the
output is close enough).

=cut

sub usable {
  system q{truss 2>/dev/null};
  return POSIX::WIFEXITED($?) && POSIX::WEXITSTATUS($?) == 1;
}

sub new {
  my($class, %args) = @_;
  my $self = bless {}, $class;

  my @run = qw(strace -d);

  if($args{follow_forks}) {
    push @run, "-f";
  }

  # TODO: Support saving this elsewhere for offline processing?
  $self->{temp} = File::Temp->new;
  push @run, "-o", $self->{temp};

  if($args{exec}) {
    push @run, ref $args{exec}
      ? @{$args{exec}}
      : (qw(sh -c), $args{exec});
  } elsif($args{pid}) {
    push @run, "-p", $args{pid};
  }

  $self->{run} = \@run;

  return $self;
}

sub call {
  my($self, @calls) = @_;
  # We need chdir to track the working directory, so add iff filtering.
  push @calls, "chdir";

  splice @{$self->{run}}, 1, 0, map { ("-t", $_) } @calls;
}

sub run {
  my($self) = @_;
  $self->{cwd} = Cwd::getcwd;
  $self->{basetime} = time;
  exec @{$self->{run}} or die "Unable to exec: $!";
}

sub pid {
  my($self, $pid) = @_;
  $self->{pid} = $pid if defined $pid;
  $self->{pid};
}

{

# System calls that take a name argument and the position
# XXX: need to handle multiple args
my %name_syscalls = (
  open => 0,
  stat => 0,
  lstat => 0,
  stat64 => 0,
  lstat64 => 0,
  chdir => 0,
  link => 0,
  unlink => 0,
  rmdir => 0,
  mkdir => 0,
  rename => 0,
  access => 0,
  execve => 0,
);

my $line_re = qr{^
  (?:([0-9]+):\s+)? # PID
  ([0-9.]+)\s+    # Clock time
  (\w+)\((.*)\)   # syscall(...args...)
  (?:
    # Return value
    \s+=\s+
    (-?[0-9]+|0x[0-9A-Fa-f]+)
    # Extra value (e.g. getpid())
    (?:\s+\[\d+\])?

  | # argc = ?
    \s+(\w+)\s+=\s+(\d+)

  | # Error
    \s+Err\#(\d+) (\w+)
  | # No return (e.g. exit)
  )
$}x;
my @line_names = qw(pid time call args return extra_name extra_value errno);

sub parse {
  my($self, $fh) = @_;

  if(!$fh) {
    open $fh, "<", $self->{temp} or die $!;
  }

  my @calls;
  while(<$fh>) {
    my %call;

    if(/Base time stamp:\s+([0-9.]+)/) {
      $self->{basetime} = $1;
      next;
    }

    @call{@line_names} = ($_ =~ $line_re);
    $call{args} = _parse_args($call{args});

    next unless defined $call{call};

    $call{walltime} = $self->{basetime} + $call{time};

    if(exists $name_syscalls{$call{call}}) {
      $call{name} = $call{args}->[$name_syscalls{$call{call}}];

      if($call{name} !~ m{^/}) {
        # Resolve realtive paths
        $call{name} = File::Spec->rel2abs($call{name}, $self->{cwd});
      }

      # Need to keep track of cwd for the relative path resolving
      if($call{call} eq 'chdir' && $call{return} == 0) {
        $self->{cwd} = $call{name};
      }
    }

    push @calls, \%call;
  }

  return \@calls;
}

}

sub _parse_args {
  my($args) = @_;

  my @args;
  while($args) {
    if($args =~ /^"/) { # String
      (my $string, $args) = extract_quotelike($args);
      ($string) = $string =~ /"(.*)"/;

      $string .= "..." if $args =~ s/\.\.//;
      push @args, $string;

    } elsif($args =~ /^([[{])/) { # Start of structure
      (my $string, $args) = extract_bracketed($args, $1);
      push @args, $string;

    } elsif($args =~ s{(0x[a-fA-F0-9]+|-?[0-9]+)(?:\s+(/\* .*? \*/))?}{}) {
      # Number (plus optional comment)
      push @args, $1;
    } elsif($args =~ s/^([^,]+)//) {
      # Constant or similar
      push @args, $1;
    }

    $args =~ s/^,\s*//;
  }

  return \@args;
}

1;
