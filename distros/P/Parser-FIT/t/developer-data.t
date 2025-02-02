use strict;
use warnings;

use Test::More;
use FindBin;

use Parser::FIT;

use Data::Dumper;
my $parser = Parser::FIT->new();

my $sessionCallbackCalled = 0;
my $recordCallbackCalled = 0;
$parser->on(record => sub {
    my $msg = shift;
    ok(exists $msg->{"Heart Rate"}, "record message contains 'Heart Rate' field");
    is($msg->{"Heart Rate"}->{value}, 126, "got expected 'Heart Rate' value");
    # Only check the first record. :)
    $parser->on(record => undef);

    $recordCallbackCalled = 1;
});

$parser->on(session => sub {
    my $msg = shift;
    ok(exists $msg->{"Doughnuts Earned"}, "session message contains earned doughnuts");
    is(sprintf("%.7f", $msg->{"Doughnuts Earned"}->{value}), 3.0008333, "earned the correct amount of doughnuts");
    $sessionCallbackCalled = 1;
});

$parser->parse($FindBin::Bin . "/test-files/activity_developerdata.fit");

ok($recordCallbackCalled, "record callback actually called");
ok($sessionCallbackCalled, "session callback actually called");

done_testing;