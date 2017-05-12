use strict;
use warnings;
use File::Spec;
use Test::More tests => 3;
use POE;
use_ok('POE::Component::SmokeBox::Backend');

my @path = qw(COMPLETELY MADE UP PATH TO PERL);
unshift @path, 'C:' if $^O eq 'MSWin32';
my $perl = File::Spec->catfile( @path );

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $backend = POE::Component::SmokeBox::Backend->check(
	type => 'CORE::Badger',
	event => '_results',
	perl => $perl,
	debug => 0,
  );
  ok( !$backend, 'The $backend is undefined' );
  return;
}

sub _stop {
  pass("Hey the poco let go of our refcount");
  undef;
}
