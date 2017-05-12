use Test::Chunks;

plan tests => 1 * chunks;

my @chunks = chunks;

is($chunks[0]->description, 'One Time');
is($chunks[1]->description, "This is the real description\nof the test.");
is($chunks[2]->description, '');
is($chunks[3]->description, '');
is($chunks[4]->description, 'Three Tips');
is($chunks[5]->description, 'Description goes here.');

__END__
=== One Time
=== Two Toes
This is the real description
of the test.
--- foo
bar
===

===
=== Three Tips

--- beezle
blob

===
Description goes here.
--- data
Some data
