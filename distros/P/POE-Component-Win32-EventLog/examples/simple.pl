use Data::Dumper;
use POE qw(Component::Win32::EventLog);
use Win32::EventLog;

$|=1;

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
	undef;
}

sub _getoldest {
	my $heap = $_[HEAP];
	my ($hashref) = $_[ARG0];
	unless ( $hashref->{result} ) {
		$eventlog->yield( 'shutdown' );
		return;
	}
	$heap->{oldest} = $hashref->{result};
	$eventlog->yield( getnumber => { event => '_getnumber' } );
	undef;
}

sub _getnumber {
	my $heap = $_[HEAP];
	my ($hashref) = $_[ARG0];
	unless ( $hashref->{result} ) {
		$eventlog->yield( 'shutdown' );
		return;
	}
	my $x = 0; my $last = 0;
	while ( $x < $hashref->{result} ) {
		$eventlog->yield( read => { event => '_event_logs', args => [ EVENTLOG_FORWARDS_READ|EVENTLOG_SEEK_READ, $heap->{oldest} + $x ], _last => $last } );
		$x++;
		if ( $x == ( $hashref->{result} - 1 ) ) { $last = 1; }
	}
	undef;
}

sub _event_logs {
	my $heap = $_[HEAP];
	my ($hashref) = $_[ARG0];

	if ( $hashref->{result} ) {
		print STDOUT Dumper( $hashref->{result} );
	}
	if ( $hashref->{_last} ) {
		$eventlog->yield( 'shutdown' );
	}
	undef;
}
