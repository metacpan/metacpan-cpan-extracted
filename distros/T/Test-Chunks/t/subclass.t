use lib 't';
use TestChunkier;

plan tests => 7;

eval "use Test::Chunks";
is("$@", '', 'ok to import parent class *after* subclass');

my @chunks = chunks;

is(ref(default_object), 'TestChunkier');

is($chunks[0]->el_nombre, 'Test One');

ok($chunks[0]->can('feedle'), 'Does feedle method exist?');

run_is xxx => 'yyy';

run_like_hell 'thunk', qr(thunk,.*ile.*unk);

__DATA__
=== Test One
--- xxx lines foo_it join
a lion
a tiger
a liger
--- yyy
foo - a lion
foo - a tiger
foo - a liger

===
--- thunk
A thunk, a pile of junk
===
--- thunk
A thunk, a jile of punk
