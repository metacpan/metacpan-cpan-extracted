use strict;
use warnings;
use File::Spec;
use Test::More;

BEGIN {
    plan skip_all => 'Currently broken on Solaris, skipping' if $^O eq 'solaris';
}

plan tests => 17;

use POE;
use_ok('POE::Component::SmokeBox::Backend');

my $perl = $^X;
my $module = 'F/FU/FUBAR/Fubar-1.00.tar.gz';

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop _results _timeout)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $backend = POE::Component::SmokeBox::Backend->smoke(
	type => 'Test::Loop',
	event => '_results',
	perl => $perl,
	module => $module,
	debug => 0,
	options => { trace => 0 },
	( $ENV{AUTOMATED_TESTING} ? ( no_grp_kill => 1 ) : () ),
  );
  isa_ok( $backend, 'POE::Component::SmokeBox::Backend' );
  diag("Waiting for the loop detection kill - could be anytime really.\n");
  $kernel->delay( '_timeout', 50 );
  return;
}

sub _stop {
  pass("Hey the poco let go of our refcount");
  undef;
}

sub _results {
  my ($kernel,$heap,$result) = @_[KERNEL,HEAP,ARG0];
  ok( $result->{$_}, "Found '$_'" ) for qw(command PID start_time end_time log status);
  ok( ref $result->{log} eq 'ARRAY', 'The log entry is an arrayref' );
  ok( scalar @{ $result->{log} } > 1, 'The log contains something' );
  ok( $result->{module} eq $module, $module );
  ok( $result->{command} eq 'smoke', "We're smoking!" );
  ok( $result->{excess_kill}, 'We got killed due to loop' );
  ok( ! exists $result->{$_}, "Did not find '$_'" ) for qw( idle_kill term_kill cb_kill );
  $kernel->delay( '_timeout' );
  return;
}

sub _timeout {
  die "Something went seriously wrong\n";
  return;
}
