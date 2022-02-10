use strict;
use warnings;
use Test::More;

use FindBin;

use Parser::FIT;

my $fit = Parser::FIT->new();

# INFO
# This is a very naive test against a known example file from the FIT SDK

my $recordMessageCount = 0;

my $result = {};

my $parser = Parser::FIT->new(on => {
    record => sub {
        my $recordMsg = shift;
        $recordMessageCount++;
    },
    _any => sub {
        my ($msgType, $msg) = (shift, shift);
        if(!exists $result->{$msgType}) {
            $result->{$msgType} = [];
        }

        push(@{$result->{$msgType}}, $msg);
    }
});

$parser->parse($FindBin::Bin . "/test-files/Activity.fit");

is($result->{session}->[0]->{total_calories}, 1305, "expected total_calories");
is(scalar @{$result->{record}}, 9143, "expected number of record messages");
is($recordMessageCount, 9143, "expected number of recordMessagesHandler callbacks");

my @expectedMessageTypes = qw/record file_id event session lap device_info activity/;
is(scalar keys %{$result}, scalar @expectedMessageTypes, "found expected number of message types");

foreach my $expectedMessageType (@expectedMessageTypes) {
    ok(exists $result->{$expectedMessageType}, "result contains message type '$expectedMessageType'");
}

done_testing;