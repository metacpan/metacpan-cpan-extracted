package Mojar::Message::BulkSms;
use Mojo::Base -base;

our $VERSION = 1.001;

use Carp 'croak';
use Mojar::Log;
use Mojo::Parameters;
use Mojo::UserAgent;
use Mojo::Util qw(encode url_escape);

# Attributes

has protocol => 'http';
has address => 'www.bulksms.co.uk';
has port => '5567';
has path => 'eapi/submission/send_sms/2/2.0';
has gateway => sub {
  my $self = shift;
  $self->path;
  $self->{path} =~ s{^/}{};
  sprintf '%s://%s:%s/%s',
      $self->protocol, $self->address, $self->port, $self->path
};

has 'username';
has 'password';
has 'recipient';
has 'sender';
has international_prefix => '44';
sub msisdn { $_[0]->{recipient} }  # read-only alias

has 'message';
has ua => sub { Mojo::UserAgent->new(request_timeout => 15) };
has log => sub { Mojar::Log->new };

# Public methods

sub send {
  my $self = shift;
  my $cb = @_ && ref $_[-1] eq 'CODE' ? pop : undef;
  return $self->handle_error({
    message => sprintf('Unhandled args (%s)', join ',', @_),
    advice => -1
  } => $cb) unless @_ % 2 == 0;
  %$self = (%$self, @_) if @_;

  my @missing = grep +(not exists $self->{$_}),
      qw(username password recipient message);
  return $self->handle_error({
    message => sprintf('Missing parameters (%s)', join ',', @missing),
    advice => -2
  } => $cb) if @missing;

  # Clean up recipient
  my $original_recipient = $self->{recipient};
  my $prefix = $self->international_prefix;
  $self->{recipient} =~ s/\D//g;  # collapse non-digits
  $self->{recipient} =~ s/^00//;  # international
  $self->{recipient} =~ s/^0/$prefix/;  # national
  $self->log->debug(sprintf 'Preparing to send SMS to %s (%s)',
      $original_recipient, $self->{recipient});
  # Clean up message
  $self->trim_message;

  my $p = Mojo::Parameters->new;
  $p->append($_ => $self->$_) for qw(username password msisdn sender message);

  return $self->submit(sprintf('%s?%s', $self->gateway, $p->to_string) => $cb);
}

sub submit {
  my ($self, $url, $cb) = @_;
  # Call the gateway
  local $ENV{MOJO_USERAGENT_DEBUG} = !! $ENV{MOJAR_SMS_DEBUG};
  if ($cb) {
    $self->ua->get($url => sub { _check_status($self, $cb, @_) });
    return $self;
  }
  else {
    my $tx = $self->ua->get($url);
    return _check_status($self, $cb, undef, $tx);
  }
}

sub _check_status {
  my ($self, $cb, undef, $tx) = (@_);

  # Check http errors
  my ($error, $advice);
  return $self->handle_error($error => $cb) if $error = $tx->error;

  # Check service errors
  eval {
    @$error{'advice', 'message'} = split /\|/, $tx->res->body;
    length($advice = $error->{advice} //= '-3') == 1 and $advice == 0;
  }
  or do {
    @$error{'advice', 'message'} = (-4, $@) if $@;
    return $self->handle_error($error => $cb);
  };

  $self->log->debug('Sent to '. $self->recipient);
  return $cb ? $cb->($self) : $self;
}

sub handle_error {
  my ($self, $error, $cb) = @_;
  $self->log->error(sprintf 'Failed with %u:%s',
      $error->{advice} //= 418, $error->{message} //= 'coded failure');
  return $cb ? $cb->($self, $error) : undef;
}

sub trim_message {
  my $self = $_[0];
  $self->{message} =~ s/^\s+//;
  $self->{message} =~ s/\s+$//;
  $self->{message} =~ s/\s\s+/ /g;
  return $self;
}

1;
__END__

=head1 NAME

Mojar::Message::BulkSms - Send SMS via BulkSMS services.

=head1 SYNOPSIS

  use Mojar::Message::BulkSms;
  my $sms = Mojar::Message::BulkSms->new(username => ..., password => ...);

  # Synchronous
  $sms->message(q{Team, have we used up all our credits yet?}),
      ->send(recipient => '0776 432 111')
      ->send(recipient => '0778 888 123');

  # Asynchronous
  my @error;
  $sms->message(q{Team, please check the async responses}),
      ->send(recipient => $recipient[0] => sub { $error[0] = $_[1] })
      ->send(recipient => $recipient[1] => sub { $error[1] = $_[1] });

=head1 DESCRIPTION

Sends SMS messages via BulkSMS services such as usa.bulksms.com and bulksms.de.

=head1 ATTRIBUTES

=over 4

=item * protocol

  $sms->protocol;  # defaults to http
  $sms->protocol('https');

=item * address

  $sms->address;  # defaults to www.bulksms.co.uk
  $sms->address('bulksms.de');

=item * port

  $sms->port;  # defaults to 5567
  $sms->port(5567);

=item * path

  $sms->path;  # defaults to eapi/submission/send_sms/2/2.0
  $sms->path('eapi/submission/send_sms/2/2.1');

=item * gateway

  $sms->log->debug('Using gateway: '. $sms->gateway);

The full URL constructed from the parts above.

=item * username

  say $sms->username;
  $sms->username('us3r');

Username for the account;

=item * password

  say $sms->password;
  $sms->password('s3cr3t');

Password for the account;

=item * recipient

  say $sms->recipient;
  $sms->recipient('077-6640 2921');

=item * sender

  say $sms->sender;
  $sms->sender('Your car');

The SMS sender.  However, in my (UK) experience this has no effect.

=item * international_prefix

  say $sms->international_prefix;  # defaults to 44
  $sms->international_prefix('33');

=item * message

  say $sms->message;
  $sms->message('Sorry, forgotten what I wanted to say now!');

The message to send.  Bear in mind that unaccepted characters get substituted by
the SMS service (often to '?').

=item * log

  $sms->log($app->log);
  $sms->log(Mojar::Log->new(path => 'log/sms.log', level => 'info'));
  $sms->log->error('Uh-oh!');

A Mojo::Log-compatible log object.  Defaults to using STDERR.

=back

=head1 METHODS

=over 4

=item new

  $sms = Mojar::Message::BulkSms->new(username => ..., password => ..., ...);

Constructor for the SMS agent.

=item send

  $sent = $sms->send;

Sends an SMS message.  Returns a false value upon failure (when used
synchronously).

  $sent = $sms->message('Boo')->send(recipient => $r1)->send(recipient => $r2);

  $sent = $sms->recipient($r3)->send(message => $m1)->send(message => $m2);

Supports method chaining, and will bail-out at the first failure if no callback
is given.

  $sms->send(sub {
    my ($agent, $error) = @_;
    ...
  });

  $sms->send(message => 'Stuff' => sub { ++$error_count if $_[1] });

Also supports asynchronous calls when provided a callback as the final argument.

=item other methods

See the source code for other methods you can override when subclassing this.

=back

=head1 REFERENCE

L<http://www.bulksms.co.uk/docs/eapi/> shows the service API.

=head1 CONFIGURATION AND ENVIRONMENT

You need to create an account at L<www.bulksms.co.uk>.

=head1 SUPPORT

See L<Mojar>.

=head1 DIAGNOSTICS

You can get behind-the-scenes debugging info by setting

  MOJAR_SMS_DEBUG=1

in your script's environment.  You should then see all the messages to and from
bulksms.co.uk as well as some progress notes.

=head1 SEE ALSO

L<Net::SMS::BulkSMS> is similar but blocking.
