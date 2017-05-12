use strict;
use warnings;
use File::Spec;
use Test::More tests => 60;
use_ok('POE::Component::SmokeBox::JobQueue');
use POE qw(Component::SmokeBox::Job Component::SmokeBox::Smoker);

my $q = POE::Component::SmokeBox::JobQueue->spawn();
isa_ok( $q, 'POE::Component::SmokeBox::JobQueue' );
ok( scalar $q->pending_jobs() == 0, 'No pending jobs' );
ok( $q->pause_queue(), 'Paused the queue' );
ok( $q->queue_paused(), 'queue_paused() seems to tally' );

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop _result _splong)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my @smokers;
  for ( 1 .. 5 ) {
    my @path = qw(COMPLETELY MADE UP PATH TO PERL);
    unshift @path, 'C:' if $^O eq 'MSWin32';
    my $perl = File::Spec->catfile( @path );
    push @smokers, POE::Component::SmokeBox::Smoker->new( perl => $perl );
  }
  my $job = POE::Component::SmokeBox::Job->new();
  my $id = $q->submit( event => '_result', job => $job, smokers => \@smokers );
  ok( $id, "We got back the id '$id'" );
  diag("Waiting five seconds for the dust to settle\n");
  ok( scalar $q->pending_jobs() == 1, 'There is one job in the queue' );
  $poe_kernel->delay( '_splong', 5 );
  return;
}

sub _stop {
  pass('The poco released our reference');
  $q->shutdown();
  return;
}

sub _splong {
  ok( scalar $q->pending_jobs() == 1, 'There is one job in the queue (still)' );
  ok( $q->resume_queue(), 'Resumed the queue' );
  ok( !$q->queue_paused(), 'queue_paused() seems to tally' );
  return;
}

sub _result {
  my ($kernel,$results) = @_[KERNEL,ARG0];
  isa_ok( $results->{job}, 'POE::Component::SmokeBox::Job' );
  isa_ok( $results->{result}, 'POE::Component::SmokeBox::Result' );
  ok( $results->{submitted}, 'There was a value for submitted' );
  ok( scalar $results->{result}->results() == 5, 'There were 5 results' );
  foreach my $res ( $results->{result}->results() ) {
     ok( ref $res eq 'HASH', 'The result is a hashref' );
     ok( $res->{$_}, "There is a '$_' entry" ) for qw(PID status start_time end_time perl log type command);
  }
  return;
}
