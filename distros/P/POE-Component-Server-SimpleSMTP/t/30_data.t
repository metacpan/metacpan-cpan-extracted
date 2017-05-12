use strict;
use Socket;
use Email::Simple;
use Email::Simple::Creator;
use Email::MessageID;
use Test::More;
use POE qw(Component::Server::SimpleSMTP Component::Client::SMTP);

if ( $^O eq 'MSWin32' ) {
	plan skip_all => 'Skipping tests on MSWin32';
}

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
);

plan tests => 10;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			smtpd_registered
			smtpd_connection
			smtpd_cmd_helo
			smtpd_cmd_mail
			smtpd_cmd_rcpt
			smtpd_cmd_data
			smtpd_data
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
	simple => 0,
	options => { trace => 0 },
  );
  isa_ok( $_[HEAP]->{smtpd}, 'POE::Component::Server::SimpleSMTP' );
  return;
}

sub smtpd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  isa_ok( $object, 'POE::Component::Server::SimpleSMTP' );
  $heap->{port} = ( sockaddr_in( $object->getsockname() ) )[0];
  POE::Component::Client::SMTP->send(
     From    => $heap->{from},
     To      => $heap->{to},
     Server  =>  '127.0.0.1',
     Port    => $heap->{port},
     Body    => $heap->{email},
     Context => 'moo',
     SMTP_Success    =>  '_success',
     SMTP_Failure    =>  '_failure',
     Debug => 0,
  );
  return;
}

sub smtpd_connection {
  pass("Got connection");
  return;
}

sub smtpd_cmd_helo {
  my ($heap,$id) = @_[HEAP,ARG0];
  pass($_[STATE]);
  $heap->{smtpd}->send_to_client( $id, '250 OK' );
  return;
}

sub smtpd_cmd_mail {
  my ($heap,$id,$args) = @_[HEAP,ARG0,ARG1];
  pass($_[STATE]);
  if ( my ($from) = $args =~ /^from:\s*<(.+)>/i ) {
	ok( $from eq $heap->{from}, 'Mail from check' );
	$heap->{smtpd}->send_to_client( $id, "250 <$from>... Sender OK" );
  }
  return;
}

sub smtpd_cmd_rcpt {
  my ($heap,$id,$args) = @_[HEAP,ARG0,ARG1];
  pass($_[STATE]);
  if ( my ($to) = $args =~ /^to:\s*<(.+)>/i ) {
	ok( $to eq $heap->{to}, 'Rcpt to check' );
	$heap->{smtpd}->send_to_client( $id, "250 <$to>... Recipient OK" );
  }
  return;
}

sub smtpd_cmd_data {
  my ($heap,$id) = @_[HEAP,ARG0];
  pass($_[STATE]);
  $heap->{smtpd}->data_mode( $id );
  $heap->{smtpd}->send_to_client( $id, '354 Enter mail, end with "." on a line by itself' );
  return;
}

sub smtpd_data {
  my ($heap,$id) = @_[HEAP,ARG0];
  pass($_[STATE]);
  my $msg_id = Email::MessageID->new;
  my $uid = $msg_id->user();
  $heap->{smtpd}->send_to_client( $id, "250 $uid Message accepted for delivery" );
  $heap->{smtpd}->shutdown();
  return;
}
