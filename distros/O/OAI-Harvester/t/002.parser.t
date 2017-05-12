
use Test::More tests => 5;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

## will we get a usable parser?

my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.yahoo.com' ]);
my $e = new_ok('Net::OAI::Error');

my $parser;
eval { $parser = Net::OAI::Harvester::_parser($e) };
ok($parser, "get decent parser from XML::SAX::ParserFactory: $@");
if ( $@ ) {
    diag("!!! This is fatal:\n!!! All subseqent tests will simply die at early stages");
    diag("Possible reasons include: No parsers installed, ParserDetails.ini does not exist");
    diag(<<"XxX");
You may force a specific parser *for the tests* by providing the environment variable NOH_ParserPackage:

NOH_ParserPackage=XML::SAX::PurePerl ./Build test

XxX
    BAIL_OUT("no decent SAX parser obtained from XML::SAX::ParserFactory");
  }
else {
    no strict 'refs';
    diag("\nNote: tests will use ".ref($parser)." ".($parser->VERSION() || '???')." assigned by XML::SAX::ParserFactory")}

## force XML::SAX::PurePerl
$XML::SAX::ParserPackage = "XML::SAX::PurePerl";
eval { $parser = Net::OAI::Harvester::_parser($e) };
isa_ok($parser, "XML::SAX::PurePerl", "forced use of XML::SAX::PurePerl parser: $@");
