package Net::SMS::RoutoMessaging;
{
  $Net::SMS::RoutoMessaging::VERSION = '0.09';
}

# ABSTRACT: Send SMS messages via the RoutoMessaging HTTP API

use strict;
use warnings;

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;

use constant {
    PROVIDER => "https://smsc5.telesignmobile.com/NewSMSsend",
    TIMEOUT  => 10
};

sub new {
    my ($class, %args) = @_;

    if (! exists $args{username} || ! exists $args{password}) {
        Carp::croak("${class}->new() requires username and password as parameters\n");
    }

    my $self = \%args;
    bless $self, $class;
}

sub send_sms {
    my ($self, %args) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(TIMEOUT);
    $ua->agent("Net::SMS::RoutoMessaging/$Net::SMS::RoutoMessaging::VERSION");

    $args{number} =~ s{\D}{}g;

    my $url  = PROVIDER;
    my $resp = $ua->request(POST $url, [ user => $self->{username}, pass => $self->{password}, %args ]);
    my $as_string = $resp->as_string;

    if (! $resp->is_success) {
        my $status = $resp->status_line;
        warn "HTTP request failed: $status\n$as_string\n";
        return 0;
    }

    my $res = $resp->content;
    chomp($res);

    my $return = 1;
    unless ($res =~ /^success/) {
        warn "Failed: $res\n";
        $return = 0;
    }

    if ($args{long_status}) {
        return wantarray ? ($return, $res, status_message($res)) : $return;
    }
    else {
        return wantarray ? ($return, $res) : $return;
    }
}

sub status_message {
    my ($status) = @_;

    my %desc = (
        success           => 'sending successful',
        error             => 'not all required parameters are present',
        auth_failed       => 'incorrect username and/or password and/or not allowed IP address',
        wrong_number      => 'the number contains non-numeric characters',
        not_allowed       => 'you are not allowed to send to this number',
        too_many_numbers  => 'sending to more than 10 numbers per request',
        no_message        => 'the message body is empty',
        too_long          => 'message is too long',
        wrong_type        => 'an incorrect message type was selected',
        wrong_message     => 'vCalendar or VCard contains wrong message',
        wrong_format      => 'the wrong message format was selected',
        bad_operator      => 'wrong operator code',
        failed            => 'internal error',
        sys_error         => 'the system error',
        'No Credits Left' => 'user has no credits'
    );

    return $desc{$status} || 'unknown or empty status';
}

1;



=pod

=head1 NAME

Net::SMS::RoutoMessaging - Send SMS messages via the RoutoMessaging HTTP API

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  # Create a testing sender
  my $sms = Net::SMS::RoutoMessaging->new(
      username => 'testuser', password => 'testpass'
  );

  # Send a message
  my ($sent, $status) = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
  );

  $sent will contain a true / false if the sending worked,
  $status will contain the status message from the provider.

  # If you just want a true / false if it workes, use :
  my $sent = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
  );

  # If you want a better description of the status message, use the
  # long_status parameter
  my ($sent, $status, $desc) = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
      long_status => 1,
  );

  if ($sent) {
      # Success, message sent
  }
  else {
      # Something failed
      warn("Failed : $status");
  }

=head1 DESCRIPTION

Perl module to send SMS messages through the HTTP API provided by RoutoMessaging
(routomessaging.com).

=head1 METHODS

=head2 new

new( username => 'testuser', password => 'testpass' )

Nothing fancy. You need to supply your username and password
in the constructor, or it will complain loudly.

=head2 send_sms

send_sms(number => $phone_number, message => $message)

Uses the API to send a message given in C<$message> to
the phone number given in C<$phone_number>.

Phone number should be given with only digits. No "+" or spaces, like this:

=over 4

=item C<1234567890>

=back

Returns a true / false value and a status message. The message is "success" if the server has accepted your query. It does not mean that the message has been delivered.
If the long_status argument is set, then it also returns a long description as the third value.

=head1 SEE ALSO

RoutoMessaging website, http://www.routomessaging.com/

=head1 AUTHOR

Terje Kristensen <terjek@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Opera Software ASA.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

