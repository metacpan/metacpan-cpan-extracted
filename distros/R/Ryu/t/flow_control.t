use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Ryu;

subtest 'simple pair pause/resume' => sub {
    my $first = new_ok('Ryu::Node');
    my $second = new_ok('Ryu::Node' => [
        parent => $first
    ]);
    ok(!$first->is_paused, 'starts off active (not paused)');
    ok(!$second->is_paused, 'starts off active (not paused)');
    is(exception {
        $first->pause;
    }, undef, 'can pause without issues');
    ok($first->is_paused, 'after pausing, ->is_paused is true');
    ok(!$second->is_paused, '... but child is not affected');
    is(exception {
        $first->resume
    }, undef, 'can resume without issues');
    ok(!$first->is_paused, 'and we are now active (not paused)') or note explain $first->{is_paused};
    ok(!$second->is_paused, 'child is still unaffected');

    is(exception {
        $second->pause
    }, undef, 'can pause child without issues');
    ok($second->is_paused, 'after pausing, ->is_paused is true');
    ok($first->is_paused, '... and parent is also paused');
    is(exception {
        $second->resume
    }, undef, 'can resume without issues');
    ok(!$second->is_paused, 'and we are now active (not paused)') or note explain $first->{is_paused};
    ok(!$first->is_paused, ' parent is also active again');
    done_testing;
};

done_testing;

