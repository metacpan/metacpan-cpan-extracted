use Test::Chunks;

plan tests => 1 * chunks;

my @chunks = chunks;

is($chunks[0]->name, 'One Time');
is($chunks[1]->name, 'Two Toes');
is($chunks[2]->name, '');
is($chunks[3]->name, 'Three Tips');

__END__
=== One Time
=== Two Toes
--- foo
===



=== Three Tips
