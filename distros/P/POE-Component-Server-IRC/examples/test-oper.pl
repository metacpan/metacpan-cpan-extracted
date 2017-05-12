#!/usr/bin/perl -w

use POE;
use POE::Component::Server::IRC::OperServ;

my ($pocosi) = POE::Component::Server::IRC::OperServ->spawn( Alias => 'ircd', Debug => 1 );

POE::Session->create (
	inline_states => { _start => \&test_start,
			   _stop  => \&test_stop,
			   ircd_cmd_rehash => \&ircd_rehash },
	heap => { Auth => 1,
		  Obj  => $pocosi },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  $kernel->post ( 'ircd' => 'register' );
  $kernel->post ( 'ircd' => 'add_i_line' => { IPMask => '*', Port => 6969 } );
  $kernel->post ( 'ircd' => 'add_operator' => { UserName => 'Flibble', Password => 'letmein' } );
  $kernel->post ( 'ircd' => 'add_listener' => { Port => 6969 } );
  $kernel->post ( 'ircd' => 'set_motd' => [ 'This is an experimental server', 'Testing POE::Component::Server::IRC', 'Enjoy!' ] );
}

sub test_stop {
	print "Test Server stopped\n";
}

sub ircd_rehash {
  my ($kernel,$heap,$input) = @_[KERNEL,HEAP,ARG0];

  if ( $heap->{Auth} == 0 ) {
	$heap->{Auth} = 1;
  } else {
	$heap->{Auth} = 0;
  }
  $kernel->call ( 'ircd' => 'configure' => Auth => $heap->{Auth} );
  $kernel->call ( 'ircd' => 'ircd_server_wallops' => { command => 'WALLOPS', prefix => $heap->{Obj}->server_name(), params => [ 'Server rehashed by ' . $input->{prefix} ] } => undef );
}
