#! /usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../lib";


package EchoProfile;

use base qw(Net::BEEP::Lite::BaseProfile);

use strict;
use warnings;

sub initialize {
  my $self = shift;

  $self->uri("http://xml.resource.org/profiles/NULL/ECHO");
  $self->SUPER::initialize(@_);
}

sub MSG {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  print STDERR "EchoProfile: handling MSG\n";

  my $resp = $session->reply_message(Message => $message,
				     Payload => $message->payload());

  $session->send_message($resp);

  $message;
}

package main;

use Net::BEEP::Lite;

use strict;
use warnings;


my $echo_profile = EchoProfile->new;

Net::BEEP::Lite::beep_listen(Port     => 10288,
			     Method   => 'fork',
			     Profiles => [ $echo_profile ],
			     Debug    => 1,
			     AllowMultipleChannels => 1);
