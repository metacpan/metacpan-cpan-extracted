use Test::Chunks;

filters 'chomp';
spec_string <<'...';
===
--- foo
1
--- bar
2
===
--- foo
3
--- bar
4
...

plan tests => 3 * chunks;

run {
    my $chunk = shift;
    is(ref($chunk), 'Test::Chunks::Chunk');
};

my @chunks = chunks;

is($chunks[0]->foo, 1);
is($chunks[0]->bar, 2);
is($chunks[1]->foo, 3);
is($chunks[1]->bar, 4);
