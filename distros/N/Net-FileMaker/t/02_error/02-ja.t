use strict;
use warnings;

use Test::More tests => 7;

use_ok('Net::FileMaker::Error');

#
#   XML Errors
#
my $xml = Net::FileMaker::Error->new(lang => 'ja', type => 'xml');
ok($xml, 'Net::FileMaker::Error loaded XML strings in Japanese');

my $xml_error_957 = $xml->get_string('957');
is($xml_error_957, 'コマンドが競合しています', 'Returned error string');

my $xml_error_minusone = $xml->get_string('-1');
is($xml_error_minusone, '原因不明のエラー', 'Returned error string on -1');

#
#   XSLT Errors
#
my $xslt = Net::FileMaker::Error->new(lang => 'ja', type => 'xslt');
ok($xslt, 'Net::FileMaker::Error loaded XSLT strings in Japanese');

my $xslt_error_10209 = $xslt->get_string('10209');
is($xslt_error_10209, 'メッセージの本文のエラー', 'Returned error string');

my $xslt_error_minusone = $xslt->get_string('-1');
is($xslt_error_minusone, '原因不明のエラー', 'Returned error string on -1');
