use strict;
use warnings;
use File::Spec;
use Test::More tests => 41;
use_ok('POE::Component::SmokeBox::JobQueue');
use POE qw(Component::SmokeBox::Job Component::SmokeBox::Smoker);

my $q = POE::Component::SmokeBox::JobQueue->spawn();
isa_ok( $q, 'POE::Component::SmokeBox::JobQueue' );
ok( scalar $q->pending_jobs() == 0, 'No pending jobs' );
ok( $q->pause_queue_now(), 'Paused the queue' );
ok( $q->queue_paused(), 'queue_paused() seems to tally' );

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop _result _splong _callback)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my @smokers;
  for ( 1 .. 2 ) {
    my @path = qw(COMPLETELY MADE UP PATH TO PERL);
    unshift @path, 'C:' if $^O eq 'MSWin32';
    my $perl = File::Spec->catfile( @path );
    push @smokers, POE::Component::SmokeBox::Smoker->new( perl => $perl,
      do_callback => $_[SESSION]->callback( '_callback', 'myargs' ) );
  }
  my $job = POE::Component::SmokeBox::Job->new();
  my $id = $q->submit( event => '_result', job => $job, smokers => \@smokers );
  ok( $id, "We got back the id '$id'" );
  ok( scalar $q->pending_jobs() == 1, 'There is one job in the queue' );
  $poe_kernel->delay( '_splong' => 1 );
  return;
}

my( $got_b_cb, $got_a_cb );

sub _callback {
  my ($kernel,$myargs,$smokeargs) = @_[KERNEL,ARG0,ARG1];

  if ( $smokeargs->[0] eq 'BEFORE' ) {
    my $num = $got_b_cb ? 2 : 1;
    ok( !$q->queue_paused(), 'queue_paused() seems to tally (BEFORE ' . $num . ')' );
    $got_b_cb++;
  } elsif ( $smokeargs->[0] eq 'AFTER' and ! $got_a_cb ) {
    # Okay, pause the jobqueue
    ok( !$q->queue_paused(), 'queue_paused() seems to tally (AFTER 1)' );
    ok( $q->pause_queue_now(), 'Paused the queue' );
    $poe_kernel->delay( '_splong' => 1 );
    $got_a_cb++;
  } elsif ( $smokeargs->[0] eq 'AFTER' and $got_a_cb ) {
    ok( !$q->queue_paused(), 'queue_paused() seems to tally (AFTER 2)' );
  } else {
    die "unknown callback!";
  }

  # return a true value so the BEFORE callback will be happy
  return 1;
}

sub _stop {
  pass('The poco released our reference');
  $q->shutdown();
  return;
}

sub _splong {
  ok( $q->queue_paused(), 'queue_paused() seems to tally (DELAY)' );
  ok( $q->resume_queue(), 'Resumed the queue (DELAY)' );
  ok( !$q->queue_paused(), 'queue_paused() seems to tally (DELAY)' );
  return;
}

sub _result {
  my ($kernel,$results) = @_[KERNEL,ARG0];
  isa_ok( $results->{job}, 'POE::Component::SmokeBox::Job' );
  isa_ok( $results->{result}, 'POE::Component::SmokeBox::Result' );
  ok( $results->{submitted}, 'There was a value for submitted' );
  ok( scalar $results->{result}->results() == 2, 'There were 2 results' );
  foreach my $res ( $results->{result}->results() ) {
     ok( ref $res eq 'HASH', 'The result is a hashref' );
     ok( $res->{$_}, "There is a '$_' entry" ) for qw(PID status start_time end_time perl log type command);
  }
  return;
}
