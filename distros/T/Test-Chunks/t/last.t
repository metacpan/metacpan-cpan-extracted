use Test::Chunks;

filters 'chomp';

plan tests => (1 * chunks) + 1;

is((1 * chunks), 3, 'Does LAST limit tests to 3?');

run {
    my $chunk = shift;
    is($chunk->test, 'all work and no play');
}

__DATA__
===
--- test
all work and no play

===
--- test
all work and no play

=== 
--- LAST
--- test
all work and no play

===
--- test
all work and no play

===
--- test
all work and no play

===
--- test
all work and no play

===
--- test
all work and no play


