use strict;
use warnings;

use Test::More tests => 7;

use_ok('Net::FileMaker::Error');

#
#   XML Errors
#
my $xml = Net::FileMaker::Error->new(lang => 'it', type => 'xml');
ok($xml, 'Net::FileMaker::Error loaded XML strings in Italian');

my $xml_error_210 = $xml->get_string('210');
is($xml_error_210, 'L\'account utente è inattivo', 'Returned error string');

my $xml_error_minusone = $xml->get_string('-1');
is($xml_error_minusone, 'Errore sconosciuto', 'Returned error string on -1');

#
#   XSLT Errors
#
my $xslt = Net::FileMaker::Error->new(lang => 'it', type => 'xslt');
ok($xslt, 'Net::FileMaker::Error loaded XSLT strings in Italian');

my $xslt_error_10205 = $xslt->get_string('10205');
is($xslt_error_10205, 'Errore “Campo CC ”', 'Returned error string');

my $xslt_error_minusone = $xslt->get_string('-1');
is($xslt_error_minusone, 'Errore sconosciuto', 'Returned error string on -1');
