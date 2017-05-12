#! /usr/bin/perl

#use FindBin qw($Bin);
#use lib "$Bin/../blib/lib";

use Net::BEEP::Lite::TLSProfile;

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

my $tls_profile = Net::BEEP::Lite::TLSProfile->new
  (Server        => 1,
   Callback      => \&tls_callback,
   Debug         => 1,
   SSL_verify_mode => 0x00,  # do not verify client cert.
   SSL_ca_file   => "./localhost_ca-cacert.pem",
   SSL_cert_file => "./localhost-cert.pem",
   SSL_key_file  => "./localhost-key.pem",
   # the password callback isn't necessary, since the
   # localhost-key.pem isn't password protected.
   SSL_passwd_cb => sub { "some_pass" });

# if you wish to see the SSL debugging info
# $IO::Socket::SSL::DEBUG = 4;

Net::BEEP::Lite::beep_listen(Port                  => 10288,
                             Method                => 'fork',
                             Profiles              => [ $tls_profile ],
                             Debug                 => 1,
                             AllowMultipleChannels => 1);

sub tls_callback {
  my $session = shift;

  print "tls_callback!\n";
  $session->add_local_profile($echo_profile);
}
