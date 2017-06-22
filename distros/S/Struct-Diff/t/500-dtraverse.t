#!perl -T

use strict;
use warnings;
use Test::More tests => 25;
use Struct::Diff qw(diff dtraverse);
use Storable qw(dclone freeze);

local $Storable::canonical = 1; # to have equal snapshots for equal by data hashes

use lib "t";
use _common qw(sdump);

my ($frst, $scnd, $d, $t);
my $opts = {
    callback => sub { $t->{sdump($_[1])}->{$_[2]} = $_[0]; $t->{TOTAL}++; 1 },
};

# no callbacks used ###
$t = undef;
$d = diff($frst, $scnd);
eval { dtraverse($d, {}) };
ok($@ =~ /^Callback must be a code reference/);

# wrong sratuses list format
$d = diff($frst, $scnd);
eval { dtraverse($d, {statuses => 1, %{$opts}}) };
ok($@ =~ /^Statuses argument must be an arrayref/);

# callback with false exit code
$d = diff($frst, $scnd);
ok(!dtraverse($d, { callback => sub { return undef } }));

### primitives ###
($frst, $scnd, $t) = (0, 0, undef);
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply($t, {TOTAL => 1,'[]' => {U => 0}}, "0 vs 0");

($frst, $scnd, $t) = (0, 0, undef);
$d = diff($frst, $scnd, "noU" => 1);
dtraverse($d, $opts);
is_deeply($t, undef, "0 vs 0, noU => 1");

($frst, $scnd, $t) = (0, 1, undef);
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply($t, {TOTAL => 2,'[]' => {N => 1,O => 0}}, "0 vs 1");

### arrays ###
($frst, $scnd, $t) = ([ 0 ], [ 0, 1 ], undef);
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply($t, {TOTAL => 2,'[[0]]' => {U => 0},'[[1]]' => {A => 1}}, "[0] vs [0,1]");

($frst, $scnd, $t) = ([ 0, 1 ], [ 0 ], undef);
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply($t, {TOTAL => 2,'[[0]]' => {U => 0},'[[1]]' => {R => 1}}, "[0,1] vs [0]");

$frst = [[ 0, 0 ]];
$scnd = [[ 1, 0 ]];
$t = undef;
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply($t, {TOTAL => 3,'[[0],[0]]' => {N => 1,O => 0},'[[0],[1]]' => {U => 0}}, "[[[0,0]]] vs [[[1,0]]]");

$frst = [0, 0, 1];
$scnd = [0, 1, 1];
$t = undef;
$d = diff($frst, $scnd, noU => 1);
dtraverse($d, $opts);
is_deeply($t, {TOTAL => 3,'[[1]]' => {I => 1,N => 1,O => 0}}, "check indexes for 'noU' array diff");

my $sub_array = [ 0, [ 11, 12 ], 2 ];
$frst = [ 0, [[ 100 ]], [ 20, 'a' ], $sub_array, 4 ];
$scnd = [ 0, [[ 100 ]], [ 20, 'b' ], $sub_array, 5 ];
$t = undef;

$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply(
    $t,
    {
        TOTAL => 8,
        '[[0]]' => {U => 0},
        '[[1]]' => {U => [[100]]},
        '[[2],[0]]' => {U => 20},
        '[[2],[1]]' => {N => 'b',O => 'a'},'[[3]]' => {U => [0,[11,12],2]},
        '[[4]]' => {N => 5,O => 4}
    },
    "complex array"
);

#### hashes ###
$frst = { 'a' => 'av' };
$scnd = { 'a' => 'av', 'b' => 'bv' };
$t = undef;
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply(
    $t,
    {TOTAL => 2,'[{keys => [\'a\']}]' => {U => 'av'},'[{keys => [\'b\']}]' => {A => 'bv'}},
    "HASH, key added"
);

$frst = { 'a' => 'av', 'b' => 'bv' };
$scnd = { 'a' => 'av' };
$t = undef;
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply(
    $t,
    {TOTAL => 2,'[{keys => [\'a\']}]' => {U => 'av'},'[{keys => [\'b\']}]' => {R => 'bv'}},
    "HASH: removed key"
);

$frst = { 'a' => 'av', 'b' => 'bv' };
$scnd = { 'a' => 'av' };
$t = undef;
$d = diff($frst, $scnd, 'trimR' => 1); # user decision (to trim and have undefs for removed items)
dtraverse($d, $opts);
is_deeply(
    $t,
    {TOTAL => 2,'[{keys => [\'a\']}]' => {U => 'av'},'[{keys => [\'b\']}]' => {R => undef}},
    "HASH: removed key, trimmedR"
);

$frst = { 'a' => 'a1', 'b' => { 'ba' => 'ba1', 'bb' => 'bb1' }, 'c' => 'c1' };
$scnd = { 'a' => 'a1', 'b' => { 'ba' => 'ba2', 'bb' => 'bb1' }, 'd' => 'd1' };
$t = undef;
$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply(
    $t,
    {
        TOTAL => 6,
        '[{keys => [\'a\']}]' => {U => 'a1'},
        '[{keys => [\'b\']},{keys => [\'ba\']}]' => {N => 'ba2',O => 'ba1'},
        '[{keys => [\'b\']},{keys => [\'bb\']}]' => {U => 'bb1'},
        '[{keys => [\'c\']}]' => {R => 'c1'},
        '[{keys => [\'d\']}]' => {A => 'd1'}
    },
    "HASH: complex test"
);

### keys sort

$frst = { '0' => 0,  '1' => 1, '02' => 2 };
$scnd = { '0' => '', '1' => 1, '02' => 2 };
$t = undef;
$d = diff($frst, $scnd);
my $cb = sub {
    my $key = (values(%{${$_[1]}[-1]}))[0]->[0];
    push(@{$t}, "$_[2]:$key=>$_[0]");
};
dtraverse($d, { callback => $cb, sortkeys => 1, statuses => [ qw{A N O R U} ] });
is_deeply(
    $t,
    ['N:0=>','O:0=>0','U:02=>2','U:1=>1'],
    "HASH: default (alphabetic) keys sort"
);


$t = undef;
dtraverse($d, { callback => $cb, sortkeys => sub { sort { $b cmp $a } @_ }, statuses => [ qw{A N O R U} ]});
is_deeply(
    $t,
    ['U:1=>1','U:02=>2','N:0=>','O:0=>0'],
    "HASH: custom alphabetic keys sort"
);

$t = undef;
dtraverse($d, { callback => $cb, sortkeys => sub { sort { $a <=> $b } @_ }, statuses => [ qw{A N O R U} ] });
is_deeply(
    $t,
    ['N:0=>','O:0=>0','U:1=>1','U:02=>2'],
    "HASH: numeric ascending sort"
);

### statuses sequence
$t = undef;
dtraverse($d, { callback => $cb, sortkeys => 1, statuses => [ qw{R O N A} ] });
is_deeply(
    $t,
    ['O:0=>0','N:0=>'],
    "HASH: statuses sequence"
);

### mixed structures ###
$frst = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 4 ]}}, 8 ]};
$scnd = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 3 ]}}, 8 ]};
$t = undef;

$d = diff($frst, $scnd);
dtraverse($d, $opts);
is_deeply(
    $t,
    {
        TOTAL => 4,
        '[{keys => [\'a\']},[0],{keys => [\'aa\']},{keys => [\'aaa\']},[0]]' => {U => 7},
        '[{keys => [\'a\']},[0],{keys => [\'aa\']},{keys => [\'aaa\']},[1]]' => {N => 3,O => 4},
        '[{keys => [\'a\']},[1]]' => {U => 8}
    },
    "MIXED: complex"
);

### check subdiff ref presence ###
$t = undef;
$cb = sub {
    push(@{$t}, $_[3]);
};

$d = diff($frst, $scnd);
dtraverse($d, { callback => $cb, sortkeys => 1 });
is_deeply(
    $t,
    [\{U => 7},\{N => 3,O => 4},\{N => 3,O => 4},\{U => 8}],
    "check subdiff ref presence"
);

### depth
$t = undef;
$d = diff($frst, $scnd);
dtraverse($d, { %{$opts}, depth => 0 });
is_deeply(
    $t,
    {
        TOTAL => 1,
        '[{keys => [\'a\']}]' => {D => [{D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},{U => 8}]}
    },
    "depth => 0"
);

$t = undef;
dtraverse($d, { %{$opts}, depth => 1 });
is_deeply(
    $t,
    {
        TOTAL => 2,
        '[{keys => [\'a\']},[0]]' => {D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},
        '[{keys => [\'a\']},[1]]' => {U => 8}
    },
    "depth => 1"
);

$t = undef;
dtraverse($d, { %{$opts}, depth => -1 });
is_deeply(
    $t,
    {
        TOTAL => 1,
        '[]' => {D => {a => {D => [{D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},{U => 8}]}}}
    },
    "depth => -1"
);

$t = undef;
dtraverse($d, { %{$opts}, depth => 1_000_000_000 });
is_deeply(
    $t,
    {
        TOTAL => 4,
        '[{keys => [\'a\']},[0],{keys => [\'aa\']},{keys => [\'aaa\']},[0]]' => {U => 7},
        '[{keys => [\'a\']},[0],{keys => [\'aa\']},{keys => [\'aaa\']},[1]]' => {N => 3,O => 4},
        '[{keys => [\'a\']},[1]]' => {U => 8}
    },
    "depth => 1_000_000_000"
);
