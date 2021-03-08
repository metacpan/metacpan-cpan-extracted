use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings;

use Protocol::FIX;
use Protocol::FIX::TagsAccessor;
use Protocol::FIX::MessageInstance;

my $proto = Protocol::FIX->new('FIX44');

subtest "simple message instance " => sub {
    my $m  = $proto->message_by_name('Heartbeat');
    my $ta = Protocol::FIX::TagsAccessor->new([$proto->field_by_name('TestReqID') => 'abc']);

    my $mi = Protocol::FIX::MessageInstance->new($m, $ta);
    ok $mi;
    is $mi->name,     'Heartbeat';
    is $mi->category, 'admin';
    is $mi->value('TestReqID'), 'abc';
};

done_testing;
