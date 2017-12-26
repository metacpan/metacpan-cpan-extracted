#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 16;

use Struct::Path qw(path_delta);

my @delta;

eval { path_delta(['garbage'],['garbage'])};
like($@, qr/Unsupported thing in the path, step #0 /);

eval {
    @delta = path_delta(
        [ {K => ['a']},[0,3],{K => ['ana', 'anc']},[1] ],
        undef
    );
};
like($@, qr/^Second path must be an arrayref/);

eval { path_delta('garbage', [ [0] ]) };
like($@, qr/^First path may be undef or an arrayref/);

@delta = path_delta(
    undef,
    [ {K => ['a']},[0,3],{K => ['ana', 'anc']},[1] ]
);
is_deeply(
    \@delta,
    [ {K => ['a']},[0,3],{K => ['ana', 'anc']},[1] ],
    "First path is undef"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ]
);
is_deeply(
    \@delta,
    [],
    "Equal paths"
);

@delta = path_delta(
    [ [0,3],{K => ['a']},{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ]
);
is_deeply(
    \@delta,
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    "Totally different paths"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']} ],
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ]
);
is_deeply(
    \@delta,
    [ [1] ],
    "One step added"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']} ]
);
is_deeply(
    \@delta,
    [],
    "One step removed -- no delta"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0],{K => ['ana', 'anb']},[1] ]
);
is_deeply(
    \@delta,
    [ [0],{K => ['ana', 'anb']},[1] ],
    "One array step item removed in the middle of the path"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,3,4],{K => ['ana', 'anb']},[1] ]
);
is_deeply(
    \@delta,
    [ [0,3,4],{K => ['ana', 'anb']},[1] ],
    "One array step item added in the middle of the path"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,4],{K => ['ana', 'anb']},[1] ]
);
is_deeply(
    \@delta,
    [ [0,4],{K => ['ana', 'anb']},[1] ],
    "One array step item changed in the middle of the path"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,3],{K => ['ana']},[1] ]
);
is_deeply(
    \@delta,
    [ {K => ['ana']},[1] ],
    "One hash step item removed in the middle of the path"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,3],{K => ['ana', 'anb', 'anc']},[1] ]
);
is_deeply(
    \@delta,
    [ {K => ['ana', 'anb', 'anc']},[1] ],
    "One hash step item added in the middle of the path"
);

@delta = path_delta(
    [ {K => ['a']},[0,3],{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},[0,3],{K => ['ana', 'anc']},[1] ]
);
is_deeply(
    \@delta,
    [ {K => ['ana', 'anc']},[1] ],
    "One hash step item changed in the middle of the path"
);

@delta = path_delta(
    [ {K => ['a']},sub {0},{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},sub {0},{K => ['ana', 'anc']},[1] ]
);
is_deeply(
    \@delta,
    [ {K => ['ana', 'anc']},[1] ],
    "Coderefs equal"
);

my $sub2 = sub { '' };
@delta = path_delta(
    [ {K => ['a']},sub {0},{K => ['ana', 'anb']},[1] ],
    [ {K => ['a']},$sub2,{K => ['ana', 'anc']},[1] ]
);
is_deeply(
    \@delta,
    [ $sub2,{K => ['ana', 'anc']},[1] ],
    "Different coderefs"
);

