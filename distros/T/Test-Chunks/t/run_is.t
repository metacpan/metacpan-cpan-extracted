use Test::Chunks;

plan tests => 7 * chunks;

run_is 'foo', 'bar';
run_is 'bar', 'baz';
run_is 'baz', 'foo';

for my $chunk (chunks) {
    is($chunk->foo, $chunk->bar, $chunk->name);
    is($chunk->bar, $chunk->baz, $chunk->name);
    is($chunk->baz, $chunk->foo, $chunk->name);
}

my @chunks = chunks;

is($chunks[0]->foo, "Hey Now\n");
is($chunks[1]->foo, "Holy Cow\n");

__END__


=== One
--- foo
Hey Now
--- bar
Hey Now
--- baz
Hey Now


=== Two
--- baz
Holy Cow
--- bar
Holy Cow
--- foo
Holy Cow
