#!--perl--
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 6;

BEGIN { use_ok('SMS::Send') };
BEGIN { use_ok('SMS::Send::VoIP::MS') };

my $phone = $ENV{'SMS_TEST_PHONE_NUMBER'};
my $conf  = -r '/etc/SMS-Send.ini';

SKIP: {
  skip '/etc/SMS-Send.ini not readable'               , 4 unless $conf;
  skip 'export SMS_TEST_PHONE_NUMBER={phone} required', 4 unless $phone;

  {
    my $obj = SMS::Send->new('VoIP::MS');
    isa_ok($obj, 'SMS::Send');
    ok($obj->send_sms(to=>$phone, text=>'SMS::Send send_sms test one'), 'send_sms test one');
  }

  {
    my $obj = SMS::Send::VoIP::MS->new;
    isa_ok($obj, 'SMS::Send::VoIP::MS');
    ok($obj->send_sms(to=>$phone, text=>'SMS::Send send_sms test two'), 'send_sms test two');
    diag(Dumper($obj));
  }
}
