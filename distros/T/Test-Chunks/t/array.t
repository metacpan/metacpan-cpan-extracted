use Test::Chunks;

plan tests => 1;

my ($chunk) = chunks;
is_deeply $chunk->foo, [qw(one two three)];

__DATA__


===
--- foo lines chomp array
one
two
three
