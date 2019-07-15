#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 38;

use Struct::Path qw(path);

use Storable qw(freeze);
$Storable::canonical = 1;

use lib "t";
use _common qw($s_array $s_mixed t_dump);

my (@r, $frozen_s);

# will check later it's not chaged
$frozen_s = freeze($s_mixed);

# path must be a list
eval { path($s_mixed, undef) };
like($@, qr/^Arrayref expected for path/);

# garbage in the path
eval { path($s_mixed, [ 'a' ]) };
like($@, qr/^Unsupported thing in the path, step #0/);

# garbage in the refstack
eval { path($s_mixed, [ sub { push @{$_[1]}, undef }, [0] ]) };
like($@, qr/^Reference expected for refs stack entry, step #0/);

# garbage in hash definition 1
eval { path($s_mixed, [ {garbage => ['a']} ]) };
like($@, qr/^Unsupported HASH definition, step #0/); # must be error

# garbage in hash definition 2
eval { path($s_mixed, [ {K => 'a', garbage => ['a']} ]) };
like($@, qr/^Unsupported HASH definition, step #0/); # must be error

# garbage in hash definition 3
eval { path($s_mixed, [ {K => 'a'} ]) };
like($@, qr/^Unsupported HASH keys definition, step #0/); # must be error

# wrong step type, strict
eval { path($s_mixed, [ [0] ], strict => 1) };
like($@, qr/^ARRAY expected on step #0, got HASH/);

# wrong step type, strict 2
eval { path($s_array, [ {K => 'a'} ], strict => 1) };
like($@, qr/^HASH expected on step #0, got ARRAY/);

# out of range
eval { path($s_mixed, [ {K => ['a']},[1000] ]) };
ok(!$@); # must be no error

# out of range, but strict opt used
eval { path($s_mixed, [ {K => ['a']},[1000] ], strict => 1) };
ok($@); # must be error

# out of range, but strict opt used
eval { path($s_mixed, [ {K => ['a']},[-3] ], strict => 1) };
like($@, qr/^\[-3\] doesn't exist, step #1/);

# hash key doesn't exists
eval { path($s_mixed, [ {K => ['notexists']} ]) };
ok(!$@); # must be no error

# hash key doesn't exists, but strict opt used
eval { path($s_mixed, [ {K => ['notexists']} ], strict => 1) };
like($@, qr/^\{notexists\} doesn't exist, step #0/);

# path doesn't exists
@r = path($s_mixed, [ [],{K => ['c']} ]);
ok(!@r);

# path doesn't exists
@r = path($s_mixed, [ {K => ['a']},{} ]);
ok(!@r);

# must return full struct
@r = path($s_mixed, []);
ok($frozen_s eq freeze(${$r[0]}));

# blessed thing as a structure
my $t = bless {}, "Thing";
@r = path($t, []);
is_deeply(
    \@r,
    [\bless( {}, 'Thing' )],
    "blessed thing as a structure"
);

# get
@r = path($s_mixed, [ {K => ['b']} ]);
is_deeply(
    \@r,
    [\{ba => 'vba',bb => 'vbb'}],
    "get {b}"
);

# here must be all b's subkeys values
@r = path($s_mixed, [ {K => ['b']},{} ]);
is_deeply(
    [ sort { ${$a} cmp ${$b} } @r ], # access via keys, which returns keys with random order, that's why sort result here
    [\'vba',\'vbb'],
    "get {b}{}"
);

# result must have right sequence
@r = path($s_array, [ [3],[1] ]);
is_deeply(
    \@r,
    [\[13]],
    "get [3],[1] from s_array"
);

# negative indexes
@r = path($s_array, [ [3],[-2,-1,-3] ], paths => 1);
is_deeply(
    \@r,
    [
        [[3],[1]], \[13],
        [[3],[2]], \7,
        [[3],[0]], \9
    ],
    "get [3],[-2,-1,-3] from s_array, negative indexes should be resolved in paths"
);

# result must have right sequence
@r = path($s_mixed, [ {K => ['a']},[1],[1, 0] ]);
is_deeply(
    \@r,
    [\'a1',\'a0'],
    "get {a}[1][1,0]"
);

# result must contain all items from last step
@r = path($s_mixed, [ {K => ['a']},[1],[] ]);
is_deeply(
    \@r,
    [\'a0',\'a1'],
    "get {a}[1][]"
);

# dereference result
@r = path($s_mixed, [ {K => ['a']},[1],[] ], deref => 1);
is_deeply(
    \@r,
    ['a0','a1'],
    "get {a}[1][], deref=1"
);

# result with paths
@r = path($s_mixed, [ {K => ['a']},[1],[] ], paths => 1);
is_deeply(
    \@r,
    [
        [{K => ['a']},[1],[0]], \'a0',
        [{K => ['a']},[1],[1]], \'a1'
    ],
    "get {a}[1][], paths=1"
);

# result with paths and dereference
@r = path($s_mixed, [ {K => ['a']},[1],[] ], deref => 1, paths => 1);
is_deeply(
    \@r,
    [
        [{K => ['a']},[1],[0]], 'a0',
        [{K => ['a']},[1],[1]], 'a1'
    ],
    "get {a}[1][], deref=1, paths=1"
);

# 'stack' opt
@r = path($s_mixed, [ {K => ['a']},[1],[0] ], stack => 1);
is_deeply(
    \@r,
    [[
        \{a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
        \[{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        \['a0','a1'],
        \'a0'
    ]],
    "get {a}[1][0], stack=1"
);

# 'stack' && 'deref' opts
@r = path($s_mixed, [ {K => ['a']},[1],[0] ], deref => 1, stack => 1);
is_deeply(
    \@r,
    [[
        {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
        [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        ['a0','a1'],
        'a0'
    ]],
    "get {a}[1][0], deref=1, stack=1"
);

# mixed structures
@r = path($s_mixed, [ {K => ['a']},[0],{K => ['a2c']} ]);
is_deeply(
    \@r,
    [\{a2ca => []}],
    "get {a}[0]{a2c}"
);

# regexps for keys specificators
@r = path($s_mixed, [ {K => [qr/a/]},[0],{K => [qr/a2(a|c)/]} ]);
@r = sort { (keys %{${$a}})[0] cmp (keys %{${$b}})[0] } @r; # sort by key (random keys access)
is_deeply(
    \@r,
    [\{a2aa => 0},\{a2ca => []}],
    "get {/a/}[0]{/a2(a|c)/}"
);

# mix regular keys and regexps
@r = path($s_mixed, [ {K => [qr/a/]},[0],{K => ['a2c', qr/a2(a|c)/]} ]);
push @r, sort { (keys %{${$a}})[0] cmp (keys %{${$b}})[0] } splice @r, 1; # sort last two items by key
is_deeply(
    \@r,
    [\{a2ca => []},\{a2aa => 0},\{a2ca => []}],
    "get {/a/}[0]{/a2(a|c)/,a2c} (keys has higher priority than regs)"
);

# code refs in the path
my $back = sub { # perform "step back"
    pop @{$_[0]};
    pop @{$_[1]};
};

@r = path($s_array, [ [],[],[1],$back ]);
is_deeply(
    \@r,
    [],
    "code refs in the path"
);

@r = path($s_mixed, [ {K => ['a']},[],{},{K => ['a2ca']},$back,$back ]);
is_deeply(
    \@r,
    [\{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}}],
    "code refs in the path (get {a}[]{}{a2ca}(<<2))"
);

my $defined = sub {
    return defined (${$_[1]->[-1]}) ? 1 : 0;
};

@r = path($s_mixed, [ {K => ['a']},[],{},{},$defined ]);
is_deeply(
    [sort @r],
    [\[],\0],
    "code refs in the path (grep defined)"
);

do {
    local $_ = 'must remain unchanged';

    my $data = [
        { k => 'one', v => 1 },
        { k => 'two', v => 2, s => { k => 1 } },
        { k => 'two', v => 2, s => { k => 2 } },
    ];

    my $dfltvar = sub {
        $_->{k} eq 'two' and
            exists $_->{s} and $_->{s}->{k} < 2
    };

    @r = path($data, [ [],$dfltvar,{K => ['k','s']} ]);
    is_deeply(
        \@r,
        [\'two',\{k => 1}],
        '$_ usage'
    ) || diag t_dump \@r;

    is($_, 'must remain unchanged', 'Default var ($_) locality check');
};

# test opts provided via %_
@r = path({}, [ sub { push @{$_[0]}, $_{opts} } ], assign => "foo", deref => 1, paths => 1);
is_deeply(
    \@r,
    [
        [{
            'paths' => 1,
            'deref' => 1,
            'assign' => 'foo'
        }],
        'foo'
    ],
    "opts provided via %_"
) || diag t_dump \@r;

# original structure must remain unchanged
ok($frozen_s eq freeze($s_mixed));
