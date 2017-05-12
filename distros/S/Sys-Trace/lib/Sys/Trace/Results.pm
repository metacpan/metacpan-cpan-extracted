package Sys::Trace::Results;
use strict;

=head1 NAME

Sys::Trace::Results - Results of a Sys::Trace

=head1 DESCRIPTION

This object holds the results of a trace performed via L<Sys::Trace>.

=head1 METHODS

=head2 new($trace)

Initialises the object from a given trace. Normally called via the C<results>
method of L<Sys::Trace>.

=cut

sub new {
  my($class, $trace) = @_;

  return bless $trace->parse, $class;
}

=head2 count

Returns the number of calls that are contained within this trace.

=cut

sub count {
  my($self) = @_;
  return scalar @$self;
}

=head2 calls([$call])

Return a list of all the calls. The system call name will be filtered against
C<$call> if provided (either a string or a Regexp reference).

Each element in the list will be a hash reference of the form:

  {
    name     => "/path/to/file",  # filename, if relevant
    call     => "open",           # system call name
    systime  => 0.000012,         # time spent in call
    walltime => 1277664686.665232 # 
    args     => [ ... ]           # arguments
    errno    => "ENOENT"          # errno, if error occurred
    strerror => "No such file or directory", # error string, if returned
    pid      => 1234,             # pid being traced
    return   => -1
  }

=cut

sub calls {
  my($self, $call) = @_;

  if($call) {
    $call = qr/^\Q$call\E$/ unless ref $call;
    return grep { $_->{call} =~ $call } @$self;
  } else {
    return @$self;
  }
}

=head2 files([$path])

Return a list of files that were referenced by the system calls in this trace,
optionally filtering on $path.

=cut

sub files {
  my($self, $path) = @_;

  $path = qr/^\Q$path\E/ if $path && not ref $path;

  my %files;
  for my $call(@$self) {
    next unless $call->{name};
    next unless $call->{name} =~ $path;

    $files{$call->{name}}++;
  }

  return keys %files;
}

=head1 TODO

This is currently very basic, this module should provide the ability to perform
analysis.

=head1 SEE ALSO

L<Sys::Trace> for copyright, etc.

=cut

1;
