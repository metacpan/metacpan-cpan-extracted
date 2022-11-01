# -*- perl -*-
use strict;
use warnings;
use DateTime;
use Data::Dumper qw{Dumper};
use Test::More tests => 4;

BEGIN { use_ok( 'SMS::Send::NANP::Twilio' ); }

my $to                  = $ENV{'SMS_TEST_PHONE_NUMBER'};
my $MessagingServiceSid = $ENV{'MessagingServiceSid'};
my $AccountSid          = $ENV{'AccountSid'};
my $AuthToken           = $ENV{'AuthToken'};

SKIP: {
  skip 'ENV{SMS_TEST_PHONE_NUMBER} not configured', 3 unless $to;

  my $service = SMS::Send::NANP::Twilio->new(
                                             MessagingServiceSid => $MessagingServiceSid,
                                             AccountSid          => $AccountSid,
                                             AuthToken           => $AuthToken,
                                            );

  isa_ok ($service, 'SMS::Send::NANP::Twilio');
  isa_ok ($service, 'SMS::Send::Driver');

  my $text = sprintf("Message: Test 002, Time: %s", DateTime->now);
  my $status=$service->send_sms(to => $to, text => $text);
  diag(Dumper($service->{"__data"}));
  ok($status, 'status');
}
