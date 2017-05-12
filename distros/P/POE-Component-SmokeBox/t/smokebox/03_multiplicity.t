use strict;
use warnings;
use File::Spec;
use Test::More tests => 71;
use_ok('POE::Component::SmokeBox');
use POE qw(Component::SmokeBox::Smoker Component::SmokeBox::Job);

my $smokebox =  POE::Component::SmokeBox->spawn( options => { trace => 0 }, multiplicity => 1 );
isa_ok( $smokebox, 'POE::Component::SmokeBox' );
ok( $smokebox->multiplicity(), 'Multiplicity is on' );

POE::Session->create(
  package_states => [
    'main' => [qw(_start _stop _results _terminate)],
  ],
  options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  for ( 1 .. 5 ) {
    my $perl = $^X;
    my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $perl );
    $smokebox->add_smoker( $smoker );
    $heap->{_smokers}++;
    $heap->{smoker} = $smoker if $_ == 1;
  }
  ok( scalar $smokebox->queues() == 5, 'There are five jobqueues' );
  my $job = POE::Component::SmokeBox::Job->new( type => 'Test::Idle' );
  $poe_kernel->post( $smokebox->session_id(), 'submit', job => $job, event => '_results', );
  $poe_kernel->delay( '_terminate', 60 );
  return;
}

sub _stop {
  pass('Poco let go of our reference');
  $smokebox->shutdown();
  return;
}

sub _terminate {
  die "BINGOS screwed up\n";
}

sub _results {
  my ($kernel,$heap,$results) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $results->{job}, 'POE::Component::SmokeBox::Job' );
  isa_ok( $results->{result}, 'POE::Component::SmokeBox::Result' );
  ok( $results->{submitted}, 'There was a value for submitted' );
  ok( scalar $results->{result}->results() == 1, 'There was only one result' );
  foreach my $res ( $results->{result}->results() ) {
     ok( ref $res eq 'HASH', 'The result is a hashref' );
     ok( defined $res->{$_}, "There is a '$_' entry" ) for qw(PID status start_time end_time perl log type command);
  }
  if ( $heap->{smoker} ) {
     $smokebox->del_smoker( delete $_[HEAP]->{smoker} );
     ok( scalar $smokebox->queues() == 4, 'There are four jobqueues' );
  }
  $heap->{_smokers}--;
  return if $heap->{_smokers};
  $kernel->delay( '_terminate' );
  return;
}
