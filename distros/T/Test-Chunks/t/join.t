use Test::Chunks;

plan tests => 1 * chunks;

is(next_chunk->input, 'onetwothree');
is(next_chunk->input, 'one=two=three');
is(next_chunk->input, "one\n\ntwo\n\nthree");

__DATA__
===
--- input lines chomp join
one
two
three

===
--- input lines chomp join==
one
two
three

===
--- input lines chomp join=\n\n
one
two
three
