use strict;
use warnings;
use Test::More;
use Test::Exception;

use PICA::Modification::Queue;
use PICA::Modification::TestQueue;

throws_ok { PICA::Modification::Queue->new('foo'); } 
    qr{PICA/Modification/Queue/Foo\.pm};

my $q;
foreach (
    PICA::Modification::Queue->new,
    PICA::Modification::Queue->new('hash'),
    PICA::Modification::Queue->new({type=>'hash'})
) {
    $q = $_;
    isa_ok $q, 'PICA::Modification::Queue::Hash';
};

test_queue $q, 'PICA::Modification::Queue::Hash';

done_testing;
