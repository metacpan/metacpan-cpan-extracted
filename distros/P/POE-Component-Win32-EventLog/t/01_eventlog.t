use strict;
use warnings;
use Test::More tests => 3;
use POE qw(Component::Win32::EventLog);
use Win32::EventLog;

my $eventlog = POE::Component::Win32::EventLog->spawn( source => 'System', debug => 0, options => { trace => 0 } );

POE::Session->create(
  package_states => [
  	'main' => [ qw(_start _getoldest _getnumber _event_logs) ],
  ],
  options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  $eventlog->yield( getoldest => { event => '_getoldest' } );
  return;
}

sub _getoldest {
  my $heap = $_[HEAP];
  my ($hashref) = $_[ARG0];
  unless ( $hashref->{result} ) {
    $eventlog->yield( 'shutdown' );
    return;
  }
  pass("Got oldest");
  $heap->{oldest} = $hashref->{result};
  $eventlog->yield( getnumber => { event => '_getnumber' } );
  return;
}

sub _getnumber {
  my $heap = $_[HEAP];
  my ($hashref) = $_[ARG0];
  unless ( $hashref->{result} ) {
    $eventlog->yield( 'shutdown' );
    return;
  }
  pass("Got number");
  $eventlog->yield( read => { event => '_event_logs', args => [ EVENTLOG_FORWARDS_READ|EVENTLOG_SEEK_READ, $heap->{oldest} ] } );
  return;
}

sub _event_logs {
  my $heap = $_[HEAP];
  my ($hashref) = $_[ARG0];
  ok( $hashref->{result}, 'Got a record' );
  $eventlog->yield( 'shutdown' );
  return;
}
