use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::Refcount;

use Variable::Disposition;
# Ignore failures here
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import('TAP');
};

use Ryu;

subtest 'high/low watermark' => sub {
    my $src = new_ok('Ryu::Source');
    my $buffer = $src->as_buffer(
        low  => 2,
        high => 5
    );
    is_oneref($buffer, 'have only our ref to the buffer');
    my $count = 0;
    for (qw(a b c d)) {
        $src->emit($_);
        is($buffer->size, ++$count, 'buffer size is correct');
        ok(!$src->is_paused, 'not paused');
    }
    $src->emit('e');
    is($buffer->data, 'abcde', 'buffer content is correct');
    ok($src->is_paused, 'now paused');
    $buffer->read_exactly(2)->get;
    ok($src->is_paused, 'still paused after reading 2');
    $buffer->read_exactly(1)->get;
    ok(!$src->is_paused, 'no longer paused after reading another one');
    is($buffer->data, 'de', 'buffer content is correct');
    undef $buffer;

    # Source won't be notified until there's at least one event
    $src->emit('x');

    is(exception {
        dispose($src);
    }, undef, 'and can dispose our source without error');
    done_testing;
};
done_testing;


