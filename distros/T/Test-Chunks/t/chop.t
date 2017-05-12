use Test::Chunks;

filters qw(norm trim chomp);

plan tests => 1 * chunks;

my $c = next_chunk;
is_deeply($c->input, $c->output);

$c = next_chunk;
is($c->input, $c->output);

__END__
===
--- input lines chomp chop array
one
two
three
--- output eval
[qw(on tw thre)]


===
--- input chomp chop
one
two
three
--- output eval
"one\ntwo\nthre"

