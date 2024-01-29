use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use_ok('TLV::EMV::Parser');

my $emv_parser;
lives_ok{ $emv_parser = TLV::EMV::Parser->new() } "no tags array needs to be passed in";

isa_ok($emv_parser, 'TLV::EMV::Parser');
my $emv_string = "5F280208406F1A8407A0000000041010A50F500A4D6173746572436172648701015F2A0208409A032301315F2D02656E9F120A43484153452056495341";
$emv_parser->parse($emv_string);
is_deeply($emv_parser->{result}, 
    { '5F28' => '0840', 
        '6F' => '8407A0000000041010A50F500A4D617374657243617264870101',
      '5F2A' => '0840',
        '9A' => '230131',
      '5F2D' => '656E',
      '9F12' => '43484153452056495341',
    }, "TLV::EMV::Parser test1");

$emv_string = "5F2A0208409A03230131UKNOWN";
lives_ok{ $emv_parser->parse($emv_string) } "will store the remaining segment";
is_deeply($emv_parser->{result}, { '5F2A' => '0840', '9A' => '230131' }, "TLV::EMV::Parser test2");
is($emv_parser->{remain}, "UKNOWN", "TLV::EMV::Parser remain");
is($emv_parser->{error}, "parsing incomplete", "TLV::EMV::Parser error");

done_testing();

