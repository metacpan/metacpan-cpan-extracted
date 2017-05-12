package Net::SMS::CSNetworks;
BEGIN {
  $Net::SMS::CSNetworks::VERSION = '0.07';
}

# ABSTRACT: Send SMS messages via the CSNetworks HTTP API

use strict;
use warnings;

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;

use constant {
    PROVIDER => "http://api.cs-networks.net:9011/bin/send",
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
    $ua->agent("Net::SMS::CSNetworks/$Net::SMS::CSNetworks::VERSION");

    my $url  = PROVIDER;
    my $resp = $ua->request(POST $url, [ USERNAME => $self->{username}, PASSWORD => $self->{password}, %args ]);
    my $as_string = $resp->as_string;

    if (! $resp->is_success) {
        my $status = $resp->status_line;
        warn "HTTP request failed: $status\n";
        return 0;
    }

    my $res = $resp->content;
    chomp($res);

    my $return = 1;
    my @dec_response = split(/\n/, $res);
    unless ($dec_response[2] =~ /OK/) {
        warn "Failed:" . $dec_response[2] . "s\n";
        $return = 0;
    }


        return ($dec_response[0], $dec_response[1], $dec_response[2]);
    
}



1;



=pod

=head1 NAME

Net::SMS::CSNetworks - Send SMS messages via the CSNetworks HTTP API

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  # Create a testing sender
  my $sms = Net::SMS::CSNetworks->new(
      username => 'testuser', password => 'testpass'
  );

  # Send a message
  my ($id, $status, $response) = $sms->send_sms(
        MESSAGE => "This is the test message",
        DESTADDR  => '1234567890',
  );


  $id will contain a message id given by smsc,
  $status will contain numeric status code of message from the provider.
  $response will contain textual response from the provider



=head1 DESCRIPTION

Perl module to send SMS messages through the HTTP API provided by CSNetworks
(www.cs-networks.net).

=head1 METHODS

=head2 new

new( username => 'testuser', password => 'testpass' )

You need to supply your username and password
in the constructor, or it will complain loudly.

=head2 send_sms

send_sms(DESTADDR => $phone_number, MESSAGE => $message, SOURCEADDR => $sender)

Uses the API to send a message given in C<$message> to
the phone number given in C<$phone_number>.

Phone number should be given with only digits. No "+" or spaces, like this:

=over 4

=item C<1234567890>

=back

Returns a true / false value and a status message. The message is "success" if the server has accepted your query. It does not mean that the message has been delivered.

=head1 SEE ALSO

CS Networks website, http://www.cs-networks.net/

=head1 AUTHOR

CS Network Solutions LImited <support@cs-networks.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by CS Network Solutions Limited.

This is free software, licensed under GPL

=cut


__END__

