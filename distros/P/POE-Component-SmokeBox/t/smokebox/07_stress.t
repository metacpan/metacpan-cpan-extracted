use strict;
use warnings;
use File::Spec;
use Test::More;
use POE qw(Component::SmokeBox::Smoker Component::SmokeBox::Job);

my $jobs = 25;

plan tests => 4 + ( $jobs * 13 );

use_ok('POE::Component::SmokeBox');
my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $^X );
my $smokebox =  POE::Component::SmokeBox->spawn( smokers => [ $smoker ], options => { trace => 0 });
isa_ok( $smokebox, 'POE::Component::SmokeBox' );
ok( scalar $smokebox->queues() == 1, 'There is one jobqueue' );

POE::Session->create(
  package_states => [
    'main' => [qw(_start _stop _results _time_out)],
  ],
  options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  diag("Starting $jobs jobs, this can take a while\n");
  for ( 1 .. $jobs ) {
     my $job = POE::Component::SmokeBox::Job->new( type => 'Test::Stress', command => 'smoke', module => 'Test-Excess-0.01.tar.gz' );
     $poe_kernel->post( $smokebox->session_id(), 'submit', job => $job, event => '_results', );
     $_[HEAP]->{_jobs}++;
  }
  $poe_kernel->delay( '_time_out', $jobs * 6 );
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
  ok( scalar $results->{result}->results() == 1, 'There was only one result' );
  foreach my $res ( $results->{result}->results() ) {
     ok( ref $res eq 'HASH', 'The result is a hashref' );
     ok( defined $res->{$_}, "There is a '$_' entry" ) for qw(PID status start_time end_time perl log type command);
  }
  $heap->{_jobs}--;
  $kernel->delay( '_time_out' ) if $heap->{_jobs} <= 0;
  return;
}
