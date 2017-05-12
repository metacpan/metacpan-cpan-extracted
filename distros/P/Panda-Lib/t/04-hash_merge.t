use 5.012;
use warnings;
use Panda::Lib qw/hash_merge :const/;
use Test::More;
use Test::Deep;

my $ret;
my $h1d = {a => 1, b => 2, c => 3, d => 4};
my $h1s = {c => 'c', d => 'd', e => 'e', f => 'f'};
$ret = hash_merge($h1d, $h1s);
cmp_deeply($h1d, merge_hash(merge_hash({}, $h1d), $h1s));
is($ret, $h1d); # check that the same hashref is returned 

my $h2d = {a => 1, b => 2, c => {aa => 1, bb => 2}};
my $h2s = {a => 10, d => 123, c => {cc => 3}};
hash_merge($h2d, $h2s);
cmp_deeply($h2d, merge_hash(merge_hash({}, $h2d), $h2s));

sub merge_hash {
    my ($hash1, $hash2) = (shift, shift);
    while (my ($k, $v2) = each %$hash2) {
        my $v1 = $hash1->{$k};
        if (ref($v1) eq 'HASH' && ref($v2) eq 'HASH') { merge_hash($v1, $v2) }
        else { $hash1->{$k} = $v2 }
    }
    return $hash1;
}

# array concat
my $aa = {x => [1,2,3], y => 10};
my $bb = {x => [3,4,5], y => 20, z => 5, k => 'abcd'};
hash_merge($aa, $bb, MERGE_ARRAY_CONCAT);
cmp_deeply($aa, {x => [1,2,3,3,4,5], y => 20, z => 5, k => 'abcd'});

# check that values are aliases
chop($bb->{k});
ok($bb->{k} eq 'abc' and $aa->{k} eq 'abc');
$bb->{x}[0]++;
ok($bb->{x}[0] == 4 and $aa->{x}[3] == 4);

# array merge
$aa = {x => [1,2,{a => 1}], y => 10};
$bb = {x => [3,4,{b => 2}], y => 20, z => 5, k => 'abcd'};
hash_merge($aa, $bb, MERGE_ARRAY_MERGE);
cmp_deeply($aa, {x => [3,4,{a => 1, b => 2}], y => 20, z => 5, k => 'abcd'});

# lazy + array_merge
$aa = {x => [1,2,{a => 1}], y => 10};
$bb = {x => [3,4,{b => 2}], y => 20, z => 5, k => 'abcd'};
hash_merge($aa, $bb, MERGE_ARRAY_MERGE|MERGE_LAZY);
cmp_deeply($aa, {x => [1,2,{a => 1, b => 2}], y => 10, z => 5, k => 'abcd'});


# copy + lazy + array_merge
$aa = {x => [1,2,{a => 1}], y => 10};
$bb = {x => [3,4,{b => 2}], y => 20, z => [1,2,3], k => {a => 1, b => 2}};
$ret = hash_merge($aa, $bb, MERGE_ARRAY_MERGE|MERGE_LAZY|MERGE_COPY);
cmp_deeply($ret, {x => [1,2,{a => 1, b => 2}], y => 10, z => [1,2,3], k => {a => 1, b => 2}});
cmp_deeply($aa, {x => [1,2,{a => 1}], y => 10});
cmp_deeply($bb, {x => [3,4,{b => 2}], y => 20, z => [1,2,3], k => {a => 1, b => 2}});
delete $ret->{k}{a};
shift @{$ret->{z}};
shift @{$ret->{x}};
cmp_deeply($ret, {x => [2,{a => 1, b => 2}], y => 10, z => [2,3], k => {b => 2}});
cmp_deeply($aa, {x => [1,2,{a => 1}], y => 10});
cmp_deeply($bb, {x => [3,4,{b => 2}], y => 20, z => [1,2,3], k => {a => 1, b => 2}});

#check undef rewrite
$aa = {a => 1, b => 2, c => [1,2]};
$bb = {a => 2, b => undef, c => [3, undef]};
hash_merge($aa, $bb, MERGE_ARRAY_MERGE);
cmp_deeply($aa, {a => 2, b => undef, c => [3,undef]});

#check undef skip
$aa = {a => 1, b => 2, c => [1,2]};
$bb = {a => 2, b => undef, c => [3, undef]};
hash_merge($aa, $bb, MERGE_ARRAY_MERGE|MERGE_SKIP_UNDEF);
cmp_deeply($aa, {a => 2, b => 2, c => [3,2]});

#check delete undef
$aa = {a => 1, b => 2, c => [1,2]};
$bb = {a => 2, b => undef, c => undef};
hash_merge($aa, $bb);
cmp_deeply($aa, {a => 2, b => undef, c => undef});
$aa = {a => 1, b => 2, c => [1,2]};
$bb = {a => 2, b => undef, c => undef};
hash_merge($aa, $bb, MERGE_DELETE_UNDEF);
cmp_deeply($aa, {a => 2});

#check copy dest
$aa = {x => 1, y => 3};
$bb = {x => 2, s => 'str'};
$ret = hash_merge($aa, $bb, MERGE_COPY_DEST);
cmp_deeply($aa, {x => 1, y => 3});
cmp_deeply($bb, {x => 2, s => 'str'});
cmp_deeply($ret, {x => 2, y => 3, s => 'str'});
chop($ret->{s});
is($bb->{s}, 'st'); # check that $bb values are still aliased

#check copy source
$aa = {x => 1, y => 3};
$bb = {x => 2, s => 'str', d => [1,2]};
$ret = hash_merge($aa, $bb, MERGE_COPY_SOURCE);
cmp_deeply($aa, {x => 2, y => 3, s => 'str', d => [1,2]});
cmp_deeply($bb, {x => 2, s => 'str', d => [1,2]});
cmp_deeply($ret, {x => 2, y => 3, s => 'str', d => [1,2]});
is($ret, $aa);
chop($ret->{s});
shift @{$ret->{d}};
is($bb->{s}, 'str'); # check that $bb values are copied
is($ret->{d}[0], 2);
is($bb->{d}[0], 1);

#check undef as $source
$aa = {x => 1, y => 3};
$ret = hash_merge($aa, undef);
is($ret, $aa);
cmp_deeply($aa, {x => 1, y => 3});

$ret = hash_merge($aa, undef, MERGE_COPY_DEST);
ok($ret ne $aa);
delete $aa->{x};
cmp_deeply($aa, {y => 3});
cmp_deeply($ret, {x => 1, y => 3});

#check empty hash as source
$ret = hash_merge({},{});
cmp_deeply($ret, {});

#check undef as $dest
$bb = {x => 1, y => 3};
$ret = hash_merge(undef, $bb);
ok($ret ne $bb);
cmp_deeply($ret, $bb);

$ret = hash_merge(undef, undef);
cmp_deeply($ret, {});

done_testing();
