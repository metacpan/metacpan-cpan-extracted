use Test::Chunks;

filters 'eval';

plan tests => 4;

my ($chunk) = chunks;

is(ref($chunk->hash), 'HASH');
is(ref($chunk->array), 'ARRAY');
is(scalar(@{$chunk->array}), 11);
is($chunk->factorial, '362880');

__END__

=== Test
--- hash
{
    foo => 'bar',
    bar => 'hihi',
}
--- array
[ 10 .. 20 ]
--- factorial
my $x = 1;
$x *= $_ for (1 .. 9);
$x;
