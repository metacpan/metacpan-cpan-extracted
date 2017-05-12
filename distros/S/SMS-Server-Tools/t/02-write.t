#!perl

use Test::More tests => 2;

#
# write test file
#
use FindBin qw($Bin);
use SMS::Server::Tools;
use File::Temp qw/ tempfile /;
my ($sms_w, $sms_r);
my ($fh, $filename) = tempfile("GSM1.XXXXXX");
my $outfile = "$Bin/../$filename";

$sms_w = SMS::Server::Tools->new();
$sms_w->SMSFile($outfile);
$sms_w->To("555123456789");
$sms_w->Text("text text text text");
$sms_w->write;

$sms_r = SMS::Server::Tools->new();
$sms_r->SMSFile($outfile);
$sms_r->parse;

my $text3 = $sms_r->Text;
my $to3   = $sms_r->To;

is($text3, "text text text text", 'write Text');
is($to3, "555123456789", 'write To');
