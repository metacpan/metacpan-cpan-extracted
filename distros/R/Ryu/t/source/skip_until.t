use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

subtest 'coderef' => sub {
    my $first = Ryu::Source->new;
    my @actual;
    my $continue = 0;
    $first->skip_until(sub { $continue })->each(sub {
        push @actual, $_;
    });
    $first->emit('a');
    $first->emit('b');
    cmp_deeply(\@actual, [ ], 'first elements are skipped');
    $continue = 1;
    $first->emit('c');
    $first->emit('d');
    cmp_deeply(\@actual, [ 'c', 'd' ], 'next elements are passed through');
    $continue = 0;
    $first->emit('e');
    cmp_deeply(\@actual, [ 'c', 'd', 'e' ], 'we continue to emit even when codref would return false');
    done_testing;
};

subtest 'future' => sub {
    my $first = Ryu::Source->new;
    my $f = Future->new;
    my @actual;
    $first->skip_until($f)->each(sub {
        push @actual, $_;
    });
    $first->emit('a');
    $first->emit('b');
    cmp_deeply(\@actual, [ ], 'first elements are skipped');
    $f->done;
    $first->emit('c');
    $first->emit('d');
    cmp_deeply(\@actual, [ 'c', 'd' ], 'next elements are passed through');
    done_testing;
};
done_testing;

