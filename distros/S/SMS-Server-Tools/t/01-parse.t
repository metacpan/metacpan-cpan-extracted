#!perl -T

use Test::More tests => 11;

#
# parse test file
#
use FindBin qw($Bin);
use SMS::Server::Tools;

my $file = "$Bin/GSM1.yZurO4";
my $sms = SMS::Server::Tools->new({SMSFile => $file});
$sms->parse;

my $from = $sms->From;
my $from_expected = '555123456789';
is($from, $from_expected, 'Parse From');

my $from_toa = $sms->From_TOA;
my $from_toa_expected = '91 international, ISDN/telephone';
is($from_toa, $from_toa_expected, 'parse From_TOA');

my $from_smsc = $sms->From_SMSC;
my $from_smsc_expected = '555987654321';
is($from_smsc, $from_smsc_expected, 'parse From_SMSC');

my $sent = $sms->Sent;
my $sent_expected = '09-01-08 17:35:25';
is($sent, $sent_expected, 'parse Sent');

my $received = $sms->Received;
my $received_expected = '09-01-08 17:35:39';
is($received, $received_expected, 'parse Received');

my $subject = $sms->Subject;
my $subject_expected = 'GSM1';
is($subject, $subject_expected, 'parse Subject');

my $imsi = $sms->IMSI;
my $imsi_expected = '555987654321234';
is($imsi, $imsi_expected, 'parse IMSI');

my $report = $sms->Report;
my $report_expected = 'no';
is($report, $report_expected, 'parse Report');

my $alphabet = $sms->Alphabet;
my $alphabet_expected = 'ISO';
is($alphabet, $alphabet_expected, 'parse Alphabet');

my $udh = $sms->UDH;
my $udh_expected = 'false';
is($udh, $udh_expected, 'parse UDH');

my $text = $sms->Text;
my $text_expected = "This is my test sms text\non two lines.";
is($text, $text_expected, 'parse Text');

