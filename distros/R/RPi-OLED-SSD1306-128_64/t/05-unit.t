use strict;
use warnings;
use Test::More;

use RPi::OLED::SSD1306::128_64;

my $mod = 'RPi::OLED::SSD1306::128_64';

# HW-free: every validating method croaks BEFORE its XS draw call, so a bare
# blessed object exercises the checks with no panel. The singleton test stubs
# the XS init so new() runs without hardware.

# --- text_size / rect / pixel / dim / invert_display validation ---
{
    my $o = bless {}, $mod;

    eval { $o->text_size('x') };
    like $@, qr/must be an integer/, 'text_size(non-integer): croaks';

    eval { $o->rect(-1, 0, 1, 1) };  like $@, qr/X must be between 0 and 127/,   'rect: X < 0 croaks';
    eval { $o->rect(128, 0, 1, 1) }; like $@, qr/X must be between 0 and 127/,   'rect: X > 127 croaks';
    eval { $o->rect(0, -1, 1, 1) };  like $@, qr/y must be between 0 and 63/,    'rect: y < 0 croaks';
    eval { $o->rect(0, 64, 1, 1) };  like $@, qr/y must be between 0 and 63/,    'rect: y > 63 croaks';
    eval { $o->rect(0, 0, -1, 1) };  like $@, qr/width must be between 0 and 128/,  'rect: w < 0 croaks';
    eval { $o->rect(0, 0, 129, 1) }; like $@, qr/width must be between 0 and 128/,  'rect: w > 128 croaks';
    eval { $o->rect(0, 0, 1, -1) };  like $@, qr/height must be between 0 and 64/,  'rect: h < 0 croaks';
    eval { $o->rect(0, 0, 1, 65) };  like $@, qr/height must be between 0 and 64/,  'rect: h > 64 croaks';

    eval { $o->pixel(-1, 0) };  like $@, qr/X must be between 0 and 127/, 'pixel: X < 0 croaks';
    eval { $o->pixel(128, 0) }; like $@, qr/X must be between 0 and 127/, 'pixel: X > 127 croaks';
    eval { $o->pixel(0, -1) };  like $@, qr/Y must be between 0 and 63/,  'pixel: Y < 0 croaks';
    eval { $o->pixel(0, 64) };  like $@, qr/Y must be between 0 and 63/,  'pixel: Y > 63 croaks';

    eval { $o->dim(-1) }; like $@, qr/either 1 or 0/, 'dim(-1): croaks';
    eval { $o->dim(2) };  like $@, qr/either 1 or 0/, 'dim(2): croaks';
    eval { $o->invert_display(-1) }; like $@, qr/either 1 or 0/, 'invert_display(-1): croaks';
    eval { $o->invert_display(2) };  like $@, qr/either 1 or 0/, 'invert_display(2): croaks';
}

# --- singleton behaviour (F16): stub the XS init so new() runs HW-free ---
{
    no warnings qw(redefine once);
    local *RPi::OLED::SSD1306::128_64::ssd1306_begin        = sub { };
    local *RPi::OLED::SSD1306::128_64::ssd1306_display      = sub { };
    local *RPi::OLED::SSD1306::128_64::ssd1306_clearDisplay = sub { };

    my $first = $mod->new(0x3C);
    isa_ok $first, $mod;

    is $mod->new, $first,       'new(): returns the same singleton instance';
    is $mod->new(0x3C), $first, 'new(0x3C): same address, same instance, no warning';

    # F16: a second new() with a different address warns and still returns the first
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    is $mod->new(0x3D), $first, 'new(0x3D): still returns the original singleton';
    like $warn, qr/singleton/, '  ...and warns the new address/splash is ignored';
}

done_testing();
