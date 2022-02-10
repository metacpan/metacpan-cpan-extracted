use strict;
use warnings;
use 5.10.0;

use Test::More;
use Test::Exception;

use Parser::FIT;

my $fit = Parser::FIT->new();

subtest 'normal header' => sub {
    my $bytes = pack("C13", (0x10, 0x8C, 0x00, 0xDE, 0x08, 0x00, 0x00, 0x2E, 0x46, 0x49, 0x54, 0x00 ,0x00));
    my $headerInfo = $fit->_parse_header($bytes);

    is($headerInfo->{protocolVersion}, 16, 'right protocol version');
    is($headerInfo->{profile}, 140, 'right profile');
    is($headerInfo->{dataLength}, 2270, 'right data length');
    is($headerInfo->{crc}, 0, 'right crc');
};

subtest 'deprecated short header' => sub {
    my $bytes = pack("C11", (0x10, 0x8C, 0x00, 0xDE, 0x08, 0x00, 0x00, 0x2E, 0x46, 0x49, 0x54));
    my $headerInfo = $fit->_parse_header($bytes);

    is($headerInfo->{protocolVersion}, 16, 'right protocol version');
    is($headerInfo->{profile}, 140, 'right profile');
    is($headerInfo->{dataLength}, 2270, 'right data length');
    is($headerInfo->{crc}, undef, 'right crc');
};

subtest 'wrong header lengths' => sub {
    my @wrongLengths = qw/0 9 10 12 14 15/;
    foreach my $wrongLength (@wrongLengths) {
        throws_ok { $fit->_parse_header("x" x $wrongLength) } qr/Invalid headerLength/i, 'wrong header length (' . $wrongLength . ')';
    }
};

subtest 'bad header' => sub {
    my $badHeader = pack("C13", (0x10, 0x8C, 0x00, 0xDE, 0x08, 0x00, 0x00, 0x2E, 0x00, 0x00, 0x00, 0x00 ,0x00));
    throws_ok { $fit->_parse_header($badHeader) } qr/not a real FIT file/i, 'invalid header';
};

done_testing();