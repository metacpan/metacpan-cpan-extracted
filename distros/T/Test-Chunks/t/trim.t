use Test::Chunks;

plan tests => 2 * chunks;

my ($chunk1, $chunk2) = chunks;

is($chunk1->foo, "line 1\nline 2\n");
is($chunk1->bar, "line1\nline2\n");
is($chunk2->foo, "aaa\n\nbbb\n");
is($chunk2->bar, "\nxxxx\n\nyyyy\n\n");


__END__

=== One

--- foo
line 1
line 2

--- bar

line1
line2

=== Two

--- bar -trim

xxxx

yyyy

--- foo

aaa

bbb


