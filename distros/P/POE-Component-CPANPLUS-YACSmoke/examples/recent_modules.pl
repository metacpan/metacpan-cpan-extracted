use strict;
use POE qw(Component::CPANPLUS::YACSmoke);
use Getopt::Long;

$|=1;

my ($perl);

GetOptions( 'perl=s' => \$perl );

my $smoker = POE::Component::CPANPLUS::YACSmoke->spawn( alias => 'smoker',debug => 0, options => { trace => 0 } );

POE::Session->create(
	package_states => [
	   'main' => [ qw(_start _stop _results) ],
	],
	heap => { perl => $perl },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->post( 'smoker', 'recent', { event => '_results', perl => $heap->{perl} } );
  undef;
}

sub _stop {
  $poe_kernel->call( 'smoker', 'shutdown' );
  undef;
}

sub _results {
  my $job = $_[ARG0];
  print STDOUT "$_\n" for @{ $job->{recent} };
  undef;
}
