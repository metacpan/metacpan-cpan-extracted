use Test::Chunks;

plan tests => 3;

run {
    ok(1);
};

is(scalar(chunks), 1);

my ($chunk) = chunks;
is($chunk->foo, "2\n");

__DATA__
=== One
--- foo
1
=== Two
--- ONLY
--- foo
2
=== Three
--- foo
3
--- ONLY
=== Four
--- foo
4
