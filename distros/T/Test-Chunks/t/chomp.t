use Test::Chunks;

filters qw(norm trim chomp);

plan tests => 1 * chunks;

my @chunks = chunks;

is($chunks[0]->input, "I am the foo");
is($chunks[1]->input, "One\n\nTwo\n\nThree");
is($chunks[2]->input, "Che!\n");

__END__
===
--- input
I am the foo
===
--- input

One

Two

Three

===
--- input chomp -chomp
Che!

