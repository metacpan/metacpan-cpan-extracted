use strict;
use Socket;
use Email::Simple;
use Email::Simple::Creator;
use Email::MessageID;
use Test::More;
use POE qw(Component::Server::SimpleSMTP Component::Client::SMTP);

my $from = 'chris@bingosnet.co.uk';
my $to = 'gumby@gumbybra.in';
my %data = (
	from => $from,
	to => $to,
	email => Email::Simple->create(
      		header => [
        			From    => $from,
        			To      => $to,
        			Subject => 'Message in a bottle',
      		],
      		body => 'My bRain hUrts!',
	)->as_string(), 
	tests => [ 
		[ 220 => 'noop' ], 
		[ 250 => "expn blah" ],
		[ 502 => "vrfy $to" ],
		[ 252 => "mail from: <$from>" ],
		[ 250 => "rcpt to: <$to>" ],
		[ 250 => "rset" ],
		[ 250 => "rcpt to: <$to>" ],
		[ 503 => "quit" ],
	],
);

plan tests => 14;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_sock_up
			_sock_fail
			_sock_in
			_sock_err
			smtpd_registered
			smtpd_connection
			smtpd_disconnected
	)],
  ],
  heap => \%data,
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{smtpd} = POE::Component::Server::SimpleSMTP->spawn(
	address => '127.0.0.1',
	port => 0,
	options => { trace => 0 },
  );
  isa_ok( $_[HEAP]->{smtpd}, 'POE::Component::Server::SimpleSMTP' );
  return;
}

sub smtpd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  isa_ok( $object, 'POE::Component::Server::SimpleSMTP' );
  $heap->{port} = ( sockaddr_in( $object->getsockname() ) )[0];
  $heap->{factory} = POE::Wheel::SocketFactory->new(
	RemoteAddress  => '127.0.0.1',
	RemotePort     => $heap->{port},
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_fail',
  );
  return;
}

sub _sock_up {
  my ($heap,$socket) = @_[HEAP,ARG0];
  delete $heap->{factory};
  $heap->{socket} = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	InputEvent => '_sock_in',
	ErrorEvent => '_sock_err',
  );
  return;
}

sub _sock_fail {
  my $heap = $_[HEAP];
  delete $heap->{factory};
  $heap->{smtpd}->shutdown();
  return;
}

sub _sock_in {
  my ($heap,$input) = @_[HEAP,ARG0];
  my @parms = split /\s+/, $input;
  my $test = shift @{ $heap->{tests} };
  if ( $test and $test->[0] eq $parms[0] ) {
	pass($input);
	$heap->{socket}->put( $test->[1] );
	return;
  }
  pass($input);
  return;
}

sub _sock_err {
  delete $_[HEAP]->{socket};
  pass("Disconnected");
  $_[HEAP]->{smtpd}->shutdown();
  return;
}

sub smtpd_connection {
  pass($_[STATE]);
  return;
}

sub smtpd_disconnected {
  pass($_[STATE]);
  return;
}
