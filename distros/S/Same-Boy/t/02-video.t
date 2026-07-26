#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Same::Boy;
use TestROM qw(minimal_rom);

plan tests => 10;

# Introspection
{
    my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());
    ok($gb->is_cgb, 'cgb model reports is_cgb');
    ok(!$gb->is_sgb, 'cgb model is not sgb');
    is($gb->model, 'cgb', 'model accessor');
    like($gb->rom_title, qr/\A[\x00-\x7f]*\z/, 'rom_title is ascii-ish');
    like($gb->rom_crc32, qr/\A\d+\z/, 'rom_crc32 is numeric');
}

{
    my $gb = Same::Boy->new(model => 'dmg', rom => \minimal_rom());
    ok(!$gb->is_cgb, 'dmg model is not cgb');

    my ($w, $h) = $gb->dimensions;
    is("${w}x${h}", '160x144', 'dmg dimensions');

    # palette + color-correction setters should not throw and should chain
    isa_ok($gb->set_dmg_palette('dmg'), 'Same::Boy', 'set_dmg_palette chains');
    isa_ok($gb->set_color_correction('modern_balanced'),
        'Same::Boy', 'set_color_correction chains');
}

# unknown palette croaks
{
    my $gb = Same::Boy->new(model => 'dmg', rom => \minimal_rom());
    eval { $gb->set_dmg_palette('bogus') };
    like($@, qr/unknown palette/, 'unknown palette croaks');
}
