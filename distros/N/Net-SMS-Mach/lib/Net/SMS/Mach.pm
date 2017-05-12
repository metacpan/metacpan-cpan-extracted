package Net::SMS::Mach;
BEGIN {
  $Net::SMS::Mach::VERSION = '0.02';
}

# ABSTRACT: Send SMS messages via the Mach HTTP API

use strict;
use warnings;

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;
use Encode qw(encode decode);

use constant {
    PROVIDER1 => "http://gw1.promessaging.com/sms.php",
    PROVIDER2 => "http://gw2.promessaging.com/sms.php",
    TIMEOUT  => 10
};

sub new {
    my ($class, %args) = @_;

    if (! exists $args{userid} || ! exists $args{password}) {
        Carp::croak("${class}->new() requires username and password as parameters\n");
    }

    my $self = \%args;
    bless $self, $class;
}

sub send_sms {
    my ($self, %args) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(TIMEOUT);
    $ua->agent("Net::SMS::Mach/$Net::SMS::Mach::VERSION");

    $args{number} =~ s{\D}{}g;

    my $message = $args{message};
    my $enc;
    if ($args{encode}) {
        $enc = "ucs";
        $message = encode_ucs($message);
    }

    my $hash = {
        dnr => "+$args{number}",
        snr => $args{sender},
        msg => $message,
        encoding => $enc,
    };

    my $url  = $args{backup_server} ? PROVIDER2 : PROVIDER1;
    my $resp = $ua->request(POST $url, [ id => $self->{userid}, pw => $self->{password}, %$hash ]);
    my $as_string = $resp->as_string;

    if (! $resp->is_success) {
        my $status = $resp->status_line;
        warn "HTTP request failed: $status\n$as_string\n";
        return 0;
    }

    my $res = $resp->content;
    chomp($res);

    my $return = 1;
    unless ($res =~ /^\+OK/) {
        warn "Failed: $res\n";
        $return = 0;
    }

    return wantarray ? ($return, $res) : $return;
}


sub encode_ucs
{
    my $message = shift;

    utf8::decode($message);
    utf8::decode($message);
    utf8::upgrade($message);

    my $encoded = unpack('H*', encode('UCS-2BE', $message));

    return $encoded;
}
1;



=pod

=head1 NAME

Net::SMS::Mach - Send SMS messages via the Mach HTTP API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # Create a testing sender
  my $sms = Net::SMS::Mach->new(
      userid => '123456', password => 'testpass'
  );

  # Send a message
  my ($sent, $status) = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
      sender  => '+441234567890',
  );

  $sent will contain a true / false if the sending worked,
  $status will contain the status message from the provider.

  # If you just want a true / false if it workes, use :
  my $sent = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
  );

  # If your message is utf8 encoded, or you are unsure if it's iso-8859-1,
  # use the encode flag to get the message UCS encoded.
  my ($sent, $status, $desc) = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
      encode => 1,
  );

  if ($sent) {
      # Success, message sent
  }
  else {
      # Something failed
      warn("Failed : $status");
  }

=head1 DESCRIPTION

Perl module to send SMS messages through the HTTP API provided by Mach
(mach.com).

=head1 METHODS

=head2 new

new( userid => '123456', password => 'testpass' )

Nothing fancy. You need to supply your username and password
in the constructor, or it will complain loudly.

=head2 send_sms

send_sms(number => $phone_number, message => $message, encode => 0, backup_server => 1)

Uses the API to send a message given in C<$message> to
the phone number given in C<$phone_number>.

Phone number should be given with only digits, or with a "+" prefix.

=over 4

=item C<1234567890>

=back

Returns a true / false value and a status message. The message is "success" if the server has accepted your query.
This does not mean that the message has been delivered.

=head1 SEE ALSO

Mach website, http://www.mach.com/

=head1 AUTHOR

Terje Kristensen <terjek@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Opera Software ASA.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

