use strict;
use warnings;
use File::Spec;
use Test::More tests => 53;
use_ok('POE::Component::SmokeBox');
use POE qw(Component::SmokeBox::Smoker Component::SmokeBox::Job);

my @smokers;
for ( 1 .. 2 ) {
    my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $^X );
    push @smokers, $smoker;
}
my $smokebox =  POE::Component::SmokeBox->spawn( smokers => \@smokers, delay => 1 );
isa_ok( $smokebox, 'POE::Component::SmokeBox' );
ok( scalar $smokebox->queues() == 1, 'There is one jobqueue' );
ok( $smokebox->delay() == 1, 'Delay is enabled' );

POE::Session->create(
  package_states => [
    'main' => [qw(_start _stop _results _time_out)],
  ],
  options => { trace => 0 },
  heap => { smoker => shift @smokers },
);

$poe_kernel->run();
exit 0;

sub _start {
  for ( 1 .. 2 ) {
     my $job = POE::Component::SmokeBox::Job->new( type => 'Test::Idle', delay => 1 );
     ok( $job->delay() == 1, 'Delay is enabled' );
     $poe_kernel->post( $smokebox->session_id(), 'submit', job => $job, event => '_results', );
     $_[HEAP]->{_jobs}++;
  }
  $poe_kernel->delay( '_time_out', 30 );
  return;
}

sub _stop {
  pass('Poco let go of our reference');
  $smokebox->shutdown();
  return;
}

sub _time_out {
  die;
}

sub _results {
  my ($kernel,$heap,$results) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $results->{job}, 'POE::Component::SmokeBox::Job' );
  isa_ok( $results->{result}, 'POE::Component::SmokeBox::Result' );
  ok( $results->{submitted}, 'There was a value for submitted' );
  ok( scalar $results->{result}->results() == 2, 'There was only two results' );
  foreach my $res ( $results->{result}->results() ) {
     ok( ref $res eq 'HASH', 'The result is a hashref' );
     ok( defined $res->{$_}, "There is a '$_' entry" ) for qw(PID status start_time end_time perl log type command);
  }
  $smokebox->del_smoker( $_[HEAP]->{smoker} );
  ok( scalar $smokebox->queues() == 1, 'There is one jobqueue' );
  $heap->{_jobs}--;
  return if $heap->{_jobs};
  $kernel->delay( '_time_out' );
  return;
}
