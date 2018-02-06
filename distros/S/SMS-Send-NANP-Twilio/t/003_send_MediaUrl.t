# -*- perl -*-
use strict;
use warnings;
use DateTime;
use Data::Dumper qw{Dumper};
use Test::More tests => 4;

BEGIN { use_ok( 'SMS::Send::NANP::Twilio' ); }

my $to   = $ENV{'MMS_TEST_PHONE_NUMBER'};

SKIP: {
  skip 'ENV{MMS_TEST_PHONE_NUMBER} not configured', 3 unless $to;

  my $service = SMS::Send::NANP::Twilio->new;

  isa_ok ($service, 'SMS::Send::NANP::Twilio');
  isa_ok ($service, 'SMS::Send::Driver');

  my $text    = sprintf("Title: Map of Clifton, VA, Date: %s", DateTime->now);
  my $url     = 'https://maps.googleapis.com/maps/api/staticmap?size=1024x400&sensor=false&markers=Clifton,VA';
  my $status  = $service->send_sms(to => $to, text => $text, MediaUrl => $url);
  diag(Dumper($service->{"__data"}));
  ok($status, 'status');
}
