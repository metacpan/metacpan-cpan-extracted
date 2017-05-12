use strict;
use warnings;
use File::Spec;
use Test::More tests => 5;
use_ok('POE::Component::SmokeBox::JobQueue');
use POE qw(Component::SmokeBox::Job Component::SmokeBox::Smoker);

my $q = POE::Component::SmokeBox::JobQueue->spawn();
isa_ok( $q, 'POE::Component::SmokeBox::JobQueue' );
ok( scalar $q->pending_jobs() == 0, 'No pending jobs' );

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my @path = qw(COMPLETELY MADE UP PATH TO PERL);
  unshift @path, 'C:' if $^O eq 'MSWin32';
  my $perl = File::Spec->catfile( @path );
#  my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $perl );
  my $job = POE::Component::SmokeBox::Job->new();
  my $id = $q->submit( event => '_result', job => $job );
  ok( !$id, "We got no job id" );
  $q->shutdown();
  return;
}

sub _stop {
  pass('The poco released our reference');
  return;
}
