use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;
use_ok('TLV::Parser');
dies_ok{ TLV::parser->new() } "expecting to die without tags array passed in";

my $tlv_parser = TLV::Parser->new( { tag_aref => ['9F01',] } );
isa_ok($tlv_parser, 'TLV::Parser');
my $tlv_string = "9F0106000000000000";
$tlv_parser->parse($tlv_string);
is_deeply($tlv_parser->{result}, { "9F01" => "000000000000" }, "TLV::Parser test1");

$tlv_string = "9F0106000000000000ABCD";
$tlv_parser->parse($tlv_string);

is_deeply($tlv_parser->{result}, { "9F01" => "000000000000" }, "TLV::Parser test2");
is($tlv_parser->{remain}, "ABCD", "TLV::Parser remain");
is($tlv_parser->{error}, "parsing incomplete", "TLV::Parser error");

done_testing();

