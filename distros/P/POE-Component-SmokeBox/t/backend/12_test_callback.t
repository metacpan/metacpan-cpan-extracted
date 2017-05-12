use strict;
use warnings;
use File::Spec;
use Test::More tests => 19;
use POE;
use_ok('POE::Component::SmokeBox::Backend');

my $perl = $^X;
my $module = 'F/FU/FUBAR/Fubar-1.00.tar.gz';

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop _results _timeout _callback)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $backend = POE::Component::SmokeBox::Backend->smoke(
	type => 'Test::Stress',
	event => '_results',
	perl => $perl,
	module => $module,
	debug => 0,
	options => { trace => 0 },
	( $ENV{AUTOMATED_TESTING} ? ( no_grp_kill => 1 ) : () ),
	do_callback => $_[SESSION]->callback( '_callback', 'myargs' ),
  );
  isa_ok( $backend, 'POE::Component::SmokeBox::Backend' );
  $kernel->delay( '_timeout', 50 );
  return;
}

my $got_before_cb = 0;
my $got_after_cb = 0;

sub _callback {
  my ($kernel,$myargs,$smokeargs) = @_[KERNEL,ARG0,ARG1];

  if ( $smokeargs->[0] eq 'BEFORE' ) {
    die "wrong order of callbacks!" if $got_after_cb;
    $got_before_cb++;
  } elsif ( $smokeargs->[0] eq 'AFTER' ) {
    die "wrong order of callbacks!" if ! $got_before_cb;
    $got_after_cb++;
  } else {
    die "unknown callback!";
  }

  # return a true value so the BEFORE callback will be happy
  return 1;
}

sub _stop {
  pass("Hey the poco let go of our refcount");
  undef;
}

sub _results {
  my ($kernel,$heap,$result) = @_[KERNEL,HEAP,ARG0];

  ok( (exists $result->{$_} and defined $result->{$_}), "Found '$_'" ) for qw(command PID start_time end_time log status);
  ok( ref $result->{log} eq 'ARRAY', 'The log entry is an arrayref' );
  ok( scalar @{ $result->{log} } > 1, 'The log contains something' );
  ok( $result->{module} eq $module, $module );
  ok( $result->{command} eq 'smoke', "We're smoking!" );
  ok( ! exists $result->{$_}, "Did not find '$_'" ) for qw( idle_kill excess_kill term_kill cb_kill );

  ok( $got_before_cb == 1, "Got callback before processing job" );
  ok( $got_after_cb == 1, "Got callback after processing job" );
  $kernel->delay( '_timeout' );
  return;
}

sub _timeout {
  die "Something went seriously wrong\n";
  return;
}
