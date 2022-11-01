# -*- perl -*-
use strict;
use warnings;
use DateTime;
use Data::Dumper qw{Dumper};
use Test::More tests => 4;

BEGIN { use_ok( 'SMS::Send' ); }
BEGIN { use_ok( 'SMS::Send::NANP::Twilio' ); }

{
  package SMS::Send::NANP::Twilio;
  no warnings;
  sub _MessagingServiceSid_default {$ENV{'MessagingServiceSid'}};
  sub _AccountSid_default          {$ENV{'AccountSid'}};
  sub _AuthToken_default           {$ENV{'AuthToken'}};
}

my $to = $ENV{'SMS_TEST_PHONE_NUMBER_API'};

SKIP: {
  skip 'ENV{SMS_TEST_PHONE_NUMBER_API} not configured', 2 unless $to;

  my $service = SMS::Send->new('NANP::Twilio');

  isa_ok ($service, 'SMS::Send');

  my $text   = sprintf("Message: Test 004, Time: %s", DateTime->now);
  my $status = $service->send_sms(to => $to, text => $text);
  ok($status, 'status');
}
