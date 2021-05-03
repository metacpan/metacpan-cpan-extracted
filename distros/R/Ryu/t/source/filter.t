use strict;
use warnings;

use Test::More;
use Test::Deep;

use Ryu;

subtest 'filter hash based on values for keys' => sub {
    my $src = Ryu::Source->new;
    my $f = $src->filter(
        some_key => 'specific value'
    )->as_list;
    $src->emit($_) for { some_key => 'wrong value' },
        { other_key => 'missing value' },
        { some_key => 'specific value' },
        { some_key => 'specific value with suffix' },
        ;
    $src->_completed->done;
    cmp_deeply([ $f->get ], [ { some_key => 'specific value' } ], 'filter operation was performed');
    done_testing;
};
subtest 'filter hash based on regex for key' => sub {
    my $src = Ryu::Source->new;
    my $f = $src->filter(
        some_key => qr/specific value/,
    )->as_list;
    $src->emit($_) for { some_key => 'wrong value' },
        { other_key => 'missing value' },
        { some_key => 'specific value' },
        { some_key => 'specific value with suffix' },
        ;
    $src->_completed->done;
    cmp_deeply([ $f->get ], [
        { some_key => 'specific value' },
        { some_key => 'specific value with suffix' },
    ], 'filter operation was performed');
    done_testing;
};
subtest 'filter hash based on array of values for key' => sub {
    my $src = Ryu::Source->new;
    my $f = $src->filter(
        xx => [qw(x y z)],
    )->as_list;
    $src->emit($_) for { xx => 4 },
        { other_key => 'missing value' },
        { xx => 'xx' },
        { xx => 'x' },
        { some_key => 'specific value with suffix' },
        { xx => 'y' },
        { xy => 'y' },
        { xx => 'z' },
        { xx => [qw(x y z)] },
        { xx => 'z' },
        { xy => 'y' },
        { xx => 'y' },
        ;
    $src->_completed->done;
    cmp_deeply([ $f->get ], [
        { xx => 'x' },
        { xx => 'y' },
        { xx => 'z' },
        { xx => 'z' },
        { xx => 'y' },
    ], 'filter operation was performed');
    done_testing;
};
done_testing;

