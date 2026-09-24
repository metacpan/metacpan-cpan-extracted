#!/usr/bin/env perl
# Regenerate the per-protocol conversion fixtures in t/data/conv-*.tsv.
#
# Each fixture is a hand-editable, self-documenting tab-separated file that
# the data-driven test t/17-conversion-fixtures.t reads as reference data.
# One row per button; a row is:
#
#   name  <TAB>  protocol  <TAB>  address  <TAB>  subaddress  <TAB>
#   command  <TAB>  pronto  <TAB>  decoded protocol  <TAB>
#   decoded address  <TAB>  decoded subaddress  <TAB>  decoded command
#
# The first five columns are the structured form (imported by protocol
# name); "pronto" is the exact Pronto Hex the library must emit for that
# structured form; the last four columns are what the library recognizes
# when that pronto is decoded back by timing. The test compares both
# directions against these columns -- it never recomputes expected values.
# Protocols with no subaddress field record -1.
#
# Timing decode cannot recover the frame variants that share a timing
# signature: NEC2 decodes as NEC, the half-header NECX1/NECX2 decode as
# SAMSUNG with the address/command bytes bit-reversed, and 48-NEC2 decodes
# as 48-NEC1. The decoded columns capture exactly that, so every row
# documents the honest decode.
#
# To change test data, edit the .tsv files directly; run this script only to
# regenerate them wholesale from the button tables below.
#
# Usage: perl tools/gen_conversion_fixtures.pl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();
my $data_dir  = "$RealBin/../t/data";

# device address => subaddress => { button name => command }
#
# The addresses deliberately exercise each protocol's full field width:
#   NEC/NEC2   8-bit address (S = ~D); 0xEF sets every bit pattern across
#              the range
#   JVC        8-bit address
#   SAMSUNG    8-bit address
#   NECX1/NECX2  real 16-bit address (S = D low byte), so the high byte must
#              be exercised: 0xB24D's low byte equals ~high byte (the pair
#              NEC1/NEC2 would wrongly normalize away) and 0xA9F6 sets the
#              full 8-bit low byte
#   48-NEC1/48-NEC2  8-bit D:S pair carrying the full 16-bit address
#              (E = ~D is cleared for IRDB rows)
#   JVC-48     8-bit D:S with OEM 3/1 and D^S^F checksum
#   SAMSUNG20  D:6 S:6 F:8
#   SAMSUNG36  16-bit address plus 20-bit command, MSB-first blocks
my %remotes = (
    'NEC'       => [ 0xEF,   -1,  {
        POWER => 69, MUTE => 71, VOLUP => 64, VOLDOWN => 68,
        CHUP => 66, CHDOWN => 74, INPUT => 7, MENU => 9,
        EXIT => 15, UP => 12, DOWN => 13, LEFT => 14,
        RIGHT => 16, OK => 21, INFO => 82,
    } ],
    'NEC2'      => [ 26,     -1,  {
        POWER => 45, MUTE => 47, VOLUP => 40, VOLDOWN => 44,
        CHUP => 42, CHDOWN => 58, INPUT => 7, MENU => 9,
        EXIT => 15, UP => 12, DOWN => 13, LEFT => 14,
        RIGHT => 16, OK => 21, INFO => 82,
    } ],
    'JVC'       => [ 131,    -1,  {
        POWER => 2, MUTE => 3, VOLUP => 4, VOLDOWN => 5,
        CHUP => 6, CHDOWN => 7, INPUT => 8, MENU => 9,
        EXIT => 10, UP => 11, DOWN => 12, LEFT => 13,
        RIGHT => 14, OK => 15, INFO => 16,
    } ],
    'SAMSUNG'   => [ 224,    -1,  {
        POWER => 64, MUTE => 13, VOLUP => 7, VOLDOWN => 11,
        CHUP => 4, CHDOWN => 12, INPUT => 18, MENU => 25,
        EXIT => 27, UP => 5, DOWN => 6, LEFT => 8,
        RIGHT => 9, OK => 19, INFO => 15,
    } ],
    'NECX1'     => [ 0xB24D, 0x4D, {
        POWER => 69, MUTE => 71, VOLUP => 64, VOLDOWN => 68,
        CHUP => 66, CHDOWN => 74, INPUT => 7, MENU => 9,
        EXIT => 15, UP => 12, DOWN => 13, LEFT => 14,
        RIGHT => 16, OK => 21, INFO => 82,
    } ],
    'NECX2'     => [ 0xA9F6, 0xF6, {
        POWER => 45, MUTE => 47, VOLUP => 40, VOLDOWN => 44,
        CHUP => 42, CHDOWN => 58, INPUT => 7, MENU => 9,
        EXIT => 15, UP => 12, DOWN => 13, LEFT => 14,
        RIGHT => 16, OK => 21, INFO => 82,
    } ],
    '48-NEC1'   => [ 77,     178, {
        POWER => 222, MUTE => 221, VOLUP => 218, VOLDOWN => 216,
        CHUP => 194, CHDOWN => 190, INPUT => 128, MENU => 124,
        EXIT => 118, UP => 104, DOWN => 105, LEFT => 106,
        RIGHT => 107, OK => 110, INFO => 115,
    } ],
    '48-NEC2'   => [ 77,     178, {
        POWER => 222, MUTE => 221, VOLUP => 218, VOLDOWN => 216,
        CHUP => 194, CHDOWN => 190, INPUT => 128, MENU => 124,
        EXIT => 118, UP => 104, DOWN => 105, LEFT => 106,
        RIGHT => 107, OK => 110, INFO => 115,
    } ],
    'JVC-48'    => [ 34,     33,  {
        POWER => 0, MUTE => 1, VOLUP => 2, VOLDOWN => 3,
        CHUP => 4, CHDOWN => 5, INPUT => 6, MENU => 7,
        EXIT => 8, UP => 9, DOWN => 10, LEFT => 11,
        RIGHT => 12, OK => 13, INFO => 14,
    } ],
    'SAMSUNG20' => [ 1,      8,   {
        POWER => 39, MUTE => 40, VOLUP => 41, VOLDOWN => 42,
        CHUP => 43, CHDOWN => 44, INPUT => 45, MENU => 46,
        EXIT => 47, UP => 48, DOWN => 49, LEFT => 50,
        RIGHT => 51, OK => 52, INFO => 53,
    } ],
    'SAMSUNG36' => [ 0x7004, -1,  {
        POWER => 0xED02F, MUTE => 0xE5CA3, VOLUP => 0xEBC43,
        VOLDOWN => 0xF023E, CHUP => 0xE52A7, CHDOWN => 0xE5AA3,
        INPUT => 0xE52F7, MENU => 0xE5CE3, EXIT => 0xE5EF3,
        UP => 0xE52B7, DOWN => 0xE52C7, LEFT => 0xE50F3,
        RIGHT => 0xE51B3, OK => 0xE51A3, INFO => 0xE54F3,
    } ],
);

# The protocol a timing decode yields for each source protocol (frame
# variants that share a signature collapse onto the most common one).
my %decoded_proto = (
    'NEC'        => 'NEC',
    'NEC2'       => 'NEC',
    'JVC'        => 'JVC',
    'SAMSUNG'    => 'SAMSUNG',
    'NECX1'      => 'SAMSUNG',
    'NECX2'      => 'SAMSUNG',
    '48-NEC1'    => '48-NEC1',
    '48-NEC2'    => '48-NEC1',
    'JVC-48'     => 'JVC-48',
    'SAMSUNG20'  => 'SAMSUNG20',
    'SAMSUNG36'  => 'SAMSUNG36',
);

for my $proto (sort keys %remotes) {
    my ($addr, $subaddr, $buttons) = @{ $remotes{$proto} };
    my $file = "$data_dir/conv-" . lc($proto) . ".tsv";
    $file =~ s/conv-48-nec1/conv-nec48/;
    $file =~ s/conv-48-nec2/conv-nec482/;
    $file =~ s/conv-jvc-48/conv-jvc48/;
    open my $fh, '>', $file or die "Cannot write $file: $!\n";

    print {$fh} "# Conversion fixture for $proto (device $addr)\n";
    print {$fh} "# Columns: name, protocol, address, subaddress, command, expected Pronto hex,\n";
    print {$fh} "#          decoded protocol, decoded address, decoded subaddress, decoded command\n";
    print {$fh} "# Tabs separate columns; lines starting with # are comments.\n";
    print {$fh} "# Edit this file to adjust test data; do not run the library here.\n";

    for my $name (sort { $buttons->{$a} <=> $buttons->{$b} } keys %$buttons) {
        my $cmd  = $buttons->{$name};
        my $code = $converter->import_code($proto,
            { address => $addr, subaddress => $subaddr, command => $cmd });

        my $pronto  = $converter->export_code($code, 'Pronto');
        my $decoded = $converter->import_format('Pronto', $pronto);
        die "$proto/$name: pronto did not decode\n" unless $decoded;

        die "$proto/$name: decoded as $decoded->protocol, expected $decoded_proto{$proto}\n"
            unless $decoded->protocol eq $decoded_proto{$proto};
        die "$proto/$name: data changed through timing decode\n"
            unless $decoded->data == $code->data;

        print {$fh} join("\t",
            $name, $proto, $addr, $subaddr, $cmd, $pronto,
            $decoded->protocol, $decoded->address, $decoded->subaddress, $decoded->command,
        ), "\n";
    }
    close $fh;
    print "wrote $file\n";
}
