use strict;
use warnings;
use File::Spec;
use Test::More tests => 18;
use_ok('POE::Component::SmokeBox::JobQueue');
use POE qw(Component::SmokeBox::Job Component::SmokeBox::Smoker);

my $q = POE::Component::SmokeBox::JobQueue->spawn( options => { trace => 0 }, );
isa_ok( $q, 'POE::Component::SmokeBox::JobQueue' );
ok( scalar $q->pending_jobs() == 0, 'No pending jobs' );

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop _result)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my @path = qw(COMPLETELY MADE UP PATH TO PERL);
  unshift @path, 'C:' if $^O eq 'MSWin32';
  my $perl = File::Spec->catfile( @path );
  my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $perl );
  my $job = POE::Component::SmokeBox::Job->new();
  my $id = $q->submit( event => '_result', job => $job, smokers => [ $smoker ] );
  ok( $id, "We got job id '$id'" );
  return;
}

sub _stop {
  pass('The poco released our reference');
  $q->shutdown();
  return;
}

sub _result {
  my ($kernel,$results) = @_[KERNEL,ARG0];
  isa_ok( $results->{job}, 'POE::Component::SmokeBox::Job' );
  isa_ok( $results->{result}, 'POE::Component::SmokeBox::Result' );
  ok( $results->{submitted}, 'There was a value for submitted' );
  ok( scalar $results->{result}->results() == 1, 'There was only one result' );
  foreach my $res ( $results->{result}->results() ) {
     ok( ref $res eq 'HASH', 'The result is a hashref' );
     ok( $res->{$_}, "There is a '$_' entry" ) for qw(PID status start_time end_time perl log type command);
  }
  return;
}
