# -*- perl -*-
use strict;
use warnings;
use DateTime;
use Data::Dumper qw{Dumper};
use Test::More tests => 4;

BEGIN { use_ok( 'SMS::Send' ); }
BEGIN { use_ok( 'SMS::Send::NANP::Twilio' ); }

my $to   = $ENV{'SMS_TEST_PHONE_NUMBER_API'};

SKIP: {
  skip 'ENV{SMS_TEST_PHONE_NUMBER_API} not configured', 2 unless $to;

  my $service = SMS::Send->new('NANP::Twilio');

  isa_ok ($service, 'SMS::Send');

  my $text = sprintf("Message: Test 2, Time: %s", DateTime->now);
  my $status=$service->send_sms(to => $to, text => $text);
  diag(Dumper($service->{"__data"})); #this is not set
  ok($status, 'status');
}
