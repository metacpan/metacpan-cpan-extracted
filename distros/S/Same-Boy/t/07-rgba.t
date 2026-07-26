use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Same::Boy;
use TestROM qw(minimal_rom);

plan tests => 6;

my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());
$gb->run_frame for 1 .. 30;

my ($w, $h) = $gb->dimensions;
my $rgba = $gb->pixels_rgba;

is(length($rgba), $w * $h * 4, 'pixels_rgba length is w*h*4');

# Alpha byte of every pixel is 0xFF.
my @a = unpack '(x3 C)*', $rgba;   # every 4th byte
is(scalar(@a), $w * $h, 'one alpha byte per pixel');
ok(!(grep { $_ != 0xFF } @a), 'all alpha bytes are 255');

# RGB parity with pixels() (which is native-endian 0x00RRGGBB words).
my @words = unpack 'L*', $gb->pixels;
my @rgb   = unpack 'C*', $rgba;
my $ok_rgb = 1;
for my $i (0 .. $#words) {
    my $w32 = $words[$i];
    $ok_rgb = 0, last if $rgb[$i*4+0] != (($w32 >> 16) & 0xFF);
    $ok_rgb = 0, last if $rgb[$i*4+1] != (($w32 >> 8)  & 0xFF);
    $ok_rgb = 0, last if $rgb[$i*4+2] != ( $w32        & 0xFF);
}
ok($ok_rgb, 'RGB bytes match pixels() words');

# Non-blank frame produced at least two distinct pixels.
my %seen; $seen{$_}++ for @words;
cmp_ok(scalar keys %seen, '>', 1, 'frame is non-blank');

# Deterministic: same frame twice yields identical rgba.
is($gb->pixels_rgba, $rgba, 'pixels_rgba is stable between calls');
