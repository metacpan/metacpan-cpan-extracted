use Test::Chunks;

my $chunks = Test::Chunks->new;
$chunks->delimiters(qw(%%% ***))->filters('lower');

plan tests => 3 * $chunks->chunks;

$chunks->run(sub {
    my $chunk = shift;
    is($chunk->foo, $chunk->bar, $chunk->name);
});

$chunks->run_is('foo', 'bar');
$chunks->run_like('foo', qr{x});

sub lower { lc(shift) }

__DATA__
%%% Test
*** foo
xyz
*** bar
XYZ
