use Test::Chunks;

filters qw(norm trim chomp);

plan tests => 1 * chunks;

is(next_chunk->input, "on\ntw\nthre\n");

__END__
===
--- input lines chomp chop unchomp join
one
two
three
