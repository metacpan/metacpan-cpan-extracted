package Sys::Trace::Impl::Ktrace;
use strict;

use Cwd ();
use File::Spec ();
use File::Temp ();
use POSIX ();

=head1 NAME

Sys::Trace::Impl::Ktrace - Sys::Trace implementation for ktrace(1)

=head1 DESCRIPTION

This should not normally be used directly, instead use L<Sys::Trace> which will
pick a suitable interface for your platform.

=cut

sub usable {
  system q{ktrace 2>/dev/null};
  return POSIX::WIFEXITED($?) && POSIX::WEXITSTATUS($?) == 1;
}

sub new {
  my($class, %args) = @_;
  my $self = bless {}, $class;

  my @run = "ktrace";

  if($args{follow_forks}) {
    push @run, "-d";
  }

  # TODO: Support saving this elsewhere for offline processing?
  $self->{temp} = File::Temp->new;
  push @run, "-f", $self->{temp};

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

  # Ktrace doesn't have an similar thing to strace's -e option. We filter out
  # afterwards instead.

  push @{$self->{only}}, @calls;
}

sub run {
  my($self) = @_;
  $self->{cwd} = Cwd::getcwd;
  exec @{$self->{run}} or die "Unable to exec: $!";
}

sub pid {
  my($self, $pid) = @_;
  $self->{pid} = $pid if defined $pid;
  $self->{pid};
}

my $line_re = qr{^\s
  ([0-9]+)\s+  # pid
  (\w+)\s+     # program
  ([0-9.]+)\s+ # time
  (\w+)\s+     # type
  (.*)         # args
$}x;
my @line_names = qw(pid program time type args);

my $call_re = qr{^(\w+)(?:\((.*)\))?$};
my @call_names = qw(call args);

my $ret_re = qr{^\w+ ([0-9]+)(?: errno ([0-9]+) (.*))?};
my @ret_names = qw(return errno sterror);

sub parse {
  my($self, $out_fh) = @_;

  if(!$out_fh) {
    open $out_fh, "-|", "kdump", "-f", $self->{temp}, "-T" or die $!;
  }

  # List of calls to filter on
  my %only;
  $only{@{$self->{only}}} = () if $self->{only};

  my @calls;
  my %cur;
  while(<$out_fh>) {
    my %call;
    @call{@line_names} = $_ =~ $line_re;

    if($call{pid}) {
      if($call{type} eq 'CALL') {
        # Reset %cur, first call
        %cur = %call;
        delete $cur{type}; # Meaningless once parsed

        # Add additional info
        @cur{@call_names} = $call{args} =~ $call_re;
        $cur{args} = [split /,/, $cur{args}];
        
      } elsif($call{type} eq 'NAMI') {
        # Name for something
        $cur{name} = _parse_str($call{args});

        if($cur{name} !~ m{^/}) {
          # Resolve realtive paths
          $cur{name} = File::Spec->rel2abs($cur{name}, $self->{cwd});
        }

      } elsif($call{type} eq 'RET' && %cur) {
        # Return
        @call{@ret_names} = $call{args} =~ $ret_re;

        $cur{systime}  = $call{time} - $cur{time};
        $cur{walltime} = delete $cur{time};

        if($cur{call} eq 'chdir' && $cur{return} == 0) {
          $self->{cwd} = $cur{name};
        }

        push @calls, {%cur} if !%only || exists $only{$cur{call}};
      }
    } else {
      # Probably GIO output, ignore for now
    }
  }

  return \@calls;
}

sub _parse_str {
  my($str) = @_;
  return ($str =~ /^"(.*)"$/)[0];
}

1;
