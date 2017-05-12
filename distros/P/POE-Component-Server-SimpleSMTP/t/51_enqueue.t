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
              'Message-ID' => Email::MessageID->new( host => 'bingosnet.co.uk' )->in_brackets(),
        			From    => $from,
        			To      => $to,
        			Subject => 'Message in a bottle',
      		],
      		body => 'My bRain hUrts!',
	)->as_string(), 
);

plan tests => 6;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_local_recipient
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
	handlers => [
	   {
	      	SESSION => $_[SESSION]->ID(),
		EVENT   => '_local_recipient',
		MATCH   => 'gumbybra.in$',
	   },
	],
	options => { trace => 0 },
  );
  isa_ok( $_[HEAP]->{smtpd}, 'POE::Component::Server::SimpleSMTP' );
  return;
}

sub smtpd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  isa_ok( $object, 'POE::Component::Server::SimpleSMTP' );
  ok( $object->enqueue(
    {
      from => $from,
      rcpt => [ $to ],
      msg  => $data{email},
    },
  ), 'Enqueued a message' );
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

sub _local_recipient {
  my $uid = $_[ARG0]->{uid};
  my $msg = $_[ARG0]->{msg};
  my $email = Email::Simple->new( $msg );
  ok( $uid, "There is a UID: $uid" );
  my $msg_id = $email->header('Message-ID');
  ok( $msg_id, "There is a Message-ID header: $msg_id" );
  ok( $msg_id =~ /^<.*>$/, "The Message-ID is in brackets" );
  $_[HEAP]->{smtpd}->shutdown();
  return;
}
