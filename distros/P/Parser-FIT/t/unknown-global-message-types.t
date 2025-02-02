use strict;
use warnings;
use Test::More;

use Parser::FIT;

my $parser = Parser::FIT->new();

my $recordCount = 0;
$parser->on(record => sub {
    my $msg = shift;
    ok(exists $msg->{timestamp}, "has timestamp key");
    is($msg->{timestamp}->{value}, 631065600, "expected timestamp value");
    $recordCount++;
});

my $data = pack("C*", map { hex } qw/0E 10 98 00 17 00 00 00 2E 46 49 54 00 00/);

my @definition = (0b01000000, 0x00, 0x00, 0x00, 0x16, 0x01, 0x01, 0x01, 0x01);
my @data = (0x00, 0x00);

my @recordDefinition = (0b01000000, 0x00, 0x00, 20, 0, 1, 253, 4, 12);
my @recordData = (0x00, 0x49, 0x96, 0x02, 0xD2);
@recordData = (0x00, 0x00, 0x00, 0x00, 0x00);

$data .= pack("C*", (@definition, @data, @recordDefinition, @recordData));

$parser->parse_data($data);

is($recordCount, 1, "record callback called once");


done_testing;