use strict;
use Test::More;
use POE qw(Component::Win32::Service);

plan 'no_plan';

my $self = POE::Component::Win32::Service->spawn();

POE::Session->create(
  package_states => [
  	'main' => [ qw(_start _services _status) ],
  ],
  options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  $self->yield( services => { event => '_services' } );
  return;
}

sub _services {
  my ($heap,$data) = @_[HEAP,ARG0];
  if ( $data->{result} and ref $data->{result} eq 'HASH' ) {
     pass('Got a hashref');
     $heap->{services} = scalar keys %{ $data->{result} };
     foreach my $service ( keys %{ $data->{result} } ) {
	pass($service);
	$self->yield( status => { event => '_status', service => $data->{result}->{$service}, _service => $service } );
     }
  }
  else {
     $self->yield( 'shutdown' );
  }
  return;
}

sub _status {
  my ($heap,$data) = @_[HEAP,ARG0];
  pass('Got status for ' . $data->{_service}) if $data->{result} and ref $data->{result} eq 'HASH';
  $heap->{services}--;
  $self->yield( 'shutdown' ) if $heap->{services} <= 0;
  return;
}
