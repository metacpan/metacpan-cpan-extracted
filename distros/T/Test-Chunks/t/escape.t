use Test::Chunks;

plan tests => 1 * chunks;

my @chunks = chunks;

is($chunks[0]->escaped, "line1\nline2");
is($chunks[1]->escaped, "	foo\n		bar\n");

__END__

===
--- escaped escape chomp
line1\nline2
===
--- escaped escape
\tfoo
\t\tbar

