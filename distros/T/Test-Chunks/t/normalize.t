use Test::Chunks;

plan tests => 4;

spec_file('t/dos_spec');

my @chunks = chunks;

is($chunks[0]->Foo, "Line 1\n\nLine 2\n");
is($chunks[0]->Bar, "Line 3\nLine 4");
is($chunks[1]->Foo, "Line 5\n\nLine 6\n");
is($chunks[1]->Bar, "Line 7\nLine 8");
