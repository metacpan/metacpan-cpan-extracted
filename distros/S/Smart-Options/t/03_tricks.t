use strict;
use Test::More;

use Smart::Options;

subtest 'stop parsing' => sub {
    my $argv = argv(qw(-a 1 -b 2 -- -c 3 -d 4));

    is $argv->{a}, 1;
    is $argv->{b}, 2;
    is_deeply $argv->{_}, ['-c', '3', '-d', '4'];
};

subtest 'negate fields' => sub {
    my $argv = Smart::Options->new->default(b => 1)->parse(qw(-a --no-b));

    ok $argv->{a};
    ok !$argv->{b};
};

subtest 'duplicates' => sub {
    my $argv = argv(qw(-x 5 -x 8 -x 0));

    is_deeply $argv->{x}, [5, 8, 0];
};

subtest 'dot notation' => sub {
    my $argv = argv(qw(--foo.x=5 --foo.y 8));

    is_deeply $argv, { foo => { x => 5, y => 8 }, '_' => [] };
};

done_testing;
