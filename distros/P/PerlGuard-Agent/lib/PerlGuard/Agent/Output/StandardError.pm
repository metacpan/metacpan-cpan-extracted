# Output method purely for testing some concepts on the agent before implementing the server

package PerlGuard::Agent::Output::StandardError;
use Moo;
extends 'PerlGuard::Agent::Output';

# Takes a profile object and saves it
sub save {
  my $self = shift;
  my $profile = shift;

  return unless $profile->should_save();

  use Data::Dumper;

  print STDERR "======\n";
  print STDERR "Profiler ID " . $profile->uuid() . "\n";
  print STDERR "Total elapsed time " . $profile->total_elapsed_time() . "\n";
  print STDERR Dumper $profile->database_transactions();
  print STDERR "======\n";
}

sub flush {
  #noop
}


1;