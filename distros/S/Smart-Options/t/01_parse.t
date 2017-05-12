use strict;
use Test::More;

use Smart::Options;

subtest 'long option' => sub {
    my $argv = argv(qw(--rif=55 --xup=9.52));

    is $argv->{rif}, 55;
    is $argv->{xup}, 9.52;
};

subtest 'short option' => sub {
    my $argv = argv(qw(-x 10 -y 21));

    is $argv->{x}, 10;
    is $argv->{y}, 21;
};

subtest 'short multi option' => sub {
    my $argv = argv(qw(-abc -n5));

    ok $argv->{a};
    ok $argv->{b};
    ok $argv->{c};
    is $argv->{n}, 5;
};

subtest 'boolean option' => sub {
    my $argv = argv(qw(-s --fr));

    ok $argv->{s};
    ok $argv->{fr};
    ok !$argv->{sp};
};

subtest 'non-hyponated options' => sub {
    my $argv = argv(qw(-x 6.82 -y 3.35 moo));

    is $argv->{x}, 6.82;
    is $argv->{y}, 3.35;
    is_deeply $argv->{_}, ['moo'];

    my $argv2 = argv(qw(foo -x 0.54 bar -y 1.12 baz));

    is $argv2->{x}, 0.54;
    is $argv2->{y}, 1.12;
    is_deeply $argv2->{_}, ['foo','bar','baz'];
};

done_testing;
