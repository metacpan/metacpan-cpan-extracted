package SMS::Send::Twilio;

use strict;
use warnings;

use 5.008_005;

use Carp;
use JSON::PP;
use WWW::Twilio::API;

use parent qw(SMS::Send::Driver);

our $VERSION = '0.18';

=encoding utf-8

=head1 NAME

SMS::Send::Twilio - SMS::Send backend for Twilio API

=head1 SYNOPSIS

  use SMS::Send;
  # Create an object. There are three required values:
  my $sender = SMS::Send->new('Twilio',
    _accountsid => 'ACb657bdcb16f06893fd127e099c070eca',
    _authtoken  => 'b857f7afe254fa86c689648447e04cff',
    _from       => '+15005550006',
  );
  
  # Send a message to me
  my $sent = $sender->send_sms(
    text => 'Messages have a limit of 160 chars',
    to   => '+31645742418',
  );
  
  # Did it send?
  if ( $sent ) {
    print "Sent test message\n";
  } else {
    print "Test message failed\n";
  }

=head1 DESCRIPTION

SMS::Send::Twilio is an SMS::Send driver for the Twilio web service.

=pod

=head2 new

  # Create a new sender using this driver
  my $sender = SMS::Send->new('Twilio',
    _accountsid => 'ACb657bdcb16f06893fd127e099c070eca',
    _authtoken  => 'b857f7afe254fa86c689648447e04cff',
    _from       => '+15005550006',
  );

The C<new> constructor takes three parameters, which should be passed
through from the L<SMS::Send> constructor.

=head2 send_sms

It's really easy; if it returns a true value, sending the message was OK.
If not we'd see an error message on STDERR.

  # Send a message to me
  my $sent = $sender->send_sms(
    text => 'Messages have a limit of 160 chars',
    to   => '+31645742418',
  );

=cut

sub new {
    my $class  = shift;
    my %params = @_;

    # check required parameters
    for my $param (qw ( _accountsid _from _authtoken )) {
        exists $params{$param}
          or croak $class . "->new requires $param parameter";
    }

    my $self = \%params;
    bless $self, $class;

    # Create twilio object
    $self->{twilio} = WWW::Twilio::API->new(
        AccountSid => $self->{_accountsid},
        AuthToken  => $self->{_authtoken},
    ) or croak $class . "->new can't set up connection: $!";

    return $self;
}

sub send_sms {
    my $self   = shift;
    my %params = @_;

    # Get the message and destination
    my $message   = delete $params{text};
    my $recipient = delete $params{to};

    my $response = $self->{twilio}->POST(
        'SMS/Messages.json',
        From => $self->{_from},
        To   => $recipient,
        Body => $message,
    );

    if ( $response->{code} == '201' ) {
        my $result = JSON::PP->new->utf8->decode( $response->{content} );
        if ( $result->{sid} ) {
            return $result->{sid};
        }
    }
    elsif ( $response->{code} == '400' ) {
        my $result = JSON::PP->new->utf8->decode( $response->{content} );
        if ( $result->{message} ) {
            croak "$result->{message}";
        }
    }

    croak "Can't send SMS: $response->{code} $response->{message}";
}

=head1 AUTHOR

Michiel Beijen E<lt>michiel.beijen@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013-2015 Michiel Beijen

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<SMS::Send>
L<WWW::Twilio::API>

=cut
