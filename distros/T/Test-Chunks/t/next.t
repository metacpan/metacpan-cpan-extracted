use Test::Chunks tests => 10;

for (1..2) {
    is (next_chunk->foo, 'This is foo');
    is (next_chunk->bar, 'This is bar');

    while (my $chunk = next_chunk) {
        pass;
    }
}

__DATA__
=== One
--- foo chomp
This is foo
=== Two
--- bar chomp
This is bar
=== Three
=== Four
=== Five
