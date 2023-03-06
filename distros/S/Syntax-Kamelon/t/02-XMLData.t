use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Syntax::Kamelon::XMLData') };

my $xml = Syntax::Kamelon::XMLData->new(xmlfile => 't/XMLData/xml.xml');

ok(defined $xml, 'Creation');

