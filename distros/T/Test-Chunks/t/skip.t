use Test::Chunks;

plan tests => 5;

run {
    ok(1);
};

is scalar(chunks), 2;

my @chunk = chunks;
is $chunk[0]->foo, "2\n";
is $chunk[1]->foo, "3\n";

__DATA__
=== One
--- SKIP
--- foo
1
=== Two
--- foo
2
=== Three
--- foo
3
=== Four
--- SKIP
--- foo
4
