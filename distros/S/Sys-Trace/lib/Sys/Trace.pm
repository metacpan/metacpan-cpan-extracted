package Sys::Trace;
use strict;
use Sys::Trace::Results;

our $VERSION = "0.03";

=head1 NAME

Sys::Trace - Interface to system call tracing interfaces

=head1 SYNOPSIS

  use Sys::Trace;

  my $trace = Sys::Trace->new(exec => [qw(ls foo)]);

  $trace->start; # Returns a PID which you can watch
  $trace->wait;  # Alternatively call this to wait on the PID

  my $result = $trace->results; # Returns a Sys::Trace::Results object

  use Cwd;
  print $result->files(getcwd . "/"); # Should show an attempt to look at "foo"
                                      # in the current directory (i.e. "ls
                                      # foo", above)

=head1 DESCRIPTION

Provides a way to programmatically run or trace a program and see the system
calls it makes.

This can be useful during testing as a way to ensure a particular file is
actually opened, or another hard to test interaction actually occurs.

Currently supported tracing mechanisms are ktrace, strace and truss.

=head1 METHODS

=cut

our @INTERFACES = qw(
  Sys::Trace::Impl::Strace
  Sys::Trace::Impl::Ktrace
  Sys::Trace::Impl::Truss
);

our @ISA;

my $interface_class = "";

=head2 new(%args)

Keys in C<%args> can be:

=over 4

=item *

B<exec>: Program and arguments to execute

=item *

B<pid>: PID of program to trace

=item *

B<follow_forks>: Follow child processes too (default is 1, set to 0 to disable)

=back

Only one of exec or pid must be provided.

=cut

sub new {
  my($class, %args) = @_;

  if(!$interface_class) {
    for my $interface(@INTERFACES) {
      my $file = $interface;
      $file  =~ s{::}{/}g;
      $file .= ".pm";
      eval { require $file } or next;

      if($interface->usable) {
        $interface_class = $interface;
        @ISA = $interface_class;
        last;
      }
    }
  }

  if(!$interface_class) {
    require Carp;
    Carp::croak("No interface for system call tracing is available on this platform");
  }

  # Default to following forks
  $args{follow_forks} = 1 unless exists $args{follow_forks};

  return $class->SUPER::new(%args);
}

=head2 start

Start running the trace.

=cut

sub start {
  my($self) = @_;

  if(!defined $self->pid(fork)) {
    die "Unable to fork: $!";
  }

  return $self->pid if $self->pid; # parent
  $self->run;
}

=head2 wait

Wait for the trace to finish

=cut

sub wait {
  my($self) = @_;

  $? if waitpid $self->pid, 0;
}

=head2 results

Return a L<Sys::Trace::Results> object populated with the results of the trace.

=cut

sub results {
  my($self) = @_;

  return Sys::Trace::Results->new($self);
}

1;

__END__

=head1 BUGS

This does what I wanted, it is probably woefully incomplete in places.

See L<http://github.com/dgl/perl-Sys-Trace>.

=head1 LICENSE

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2, as
published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING or
L<Software::License::WTFPL_2> for more details.

=head1 AUTHOR

David Leadbeater E<lt>L<dgl@dgl.cx>E<gt>, 2010

