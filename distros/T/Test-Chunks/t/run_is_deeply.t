use Test::Chunks;

filters 'eval';

plan tests => 3 * chunks;

run_is_deeply qw(foo bar);

run {
    my $chunk = shift;
    ok(ref $chunk->foo);
    ok(ref $chunk->bar);
};

__DATA__
=== Test is_deeply
--- foo
{ foo => 22, bar => 33 }
--- bar
{ bar => 33, foo => 22 }
