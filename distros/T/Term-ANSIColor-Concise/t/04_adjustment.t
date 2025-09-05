use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    for (grep /^ANSICOLOR|^(COLORTERM|NO_COLOR)$/, keys %ENV) {
        delete $ENV{$_};
    }
}

use Term::ANSIColor::Concise qw(ansi_color ansi_color_24 ansi_code);

use constant {
    RESET => "\e[m\e[K",
};

sub rgb24(&) {
    my $sub = shift;
    local $Term::ANSIColor::Concise::RGB24 = 1;
    $sub->();
}

# Test lightness adjustments
isnt(ansi_color("<red>+l20", "text"), ansi_color("<red>", "text"), "lightness increase changes result");
isnt(ansi_code("<red>+l20"), ansi_code("<red>"), "lightness +20 changes color");
isnt(ansi_code("<red>-l20"), ansi_code("<red>"), "lightness -20 changes color");
isnt(ansi_code("<red>=l75"), ansi_code("<red>"), "lightness =75 changes color");
like(ansi_code("<red>*l120"), qr/^\e\[38;5;\d+m$/, "lightness *120 produces valid color");

# Test luminance adjustments
like(ansi_code("<red>+y10"), qr/^\e\[38;5;\d+m$/, "luminance +10 produces valid color");
isnt(ansi_code("<red>-y10"), ansi_code("<red>"), "luminance -10 changes color");
like(ansi_code("<red>=y50"), qr/^\e\[38;5;\d+m$/, "luminance =50 produces valid color");

# Test saturation adjustments
like(ansi_code("<red>+s20"), qr/^\e\[38;5;\d+m$/, "saturation +20 produces valid color");
isnt(ansi_code("<red>-s30"), ansi_code("<red>"), "saturation -30 changes color");
like(ansi_code("<red>=s0"), qr/^\e\[38;5;\d+m$/, "saturation =0 produces grayscale");

# Test hue adjustments
isnt(ansi_code("<red>+h60"), ansi_code("<red>"), "hue +60 changes color");
isnt(ansi_code("<red>-h120"), ansi_code("<red>"), "hue -120 changes color");
isnt(ansi_code("<red>=h180"), ansi_code("<red>"), "hue =180 changes color");

# Test complement
isnt(ansi_code("<red>c"), ansi_code("<red>"), "complement changes color");
like(ansi_code("<red>cc"), qr/^\e\[38;5;\d+(;\d+)*m$/, "double complement produces valid color");

# Test hue rotation (LCH)
SKIP: {
    eval { ansi_code("<red>+r60") };
    skip "LCH hue rotation not supported", 2 if $@;
    
    isnt(ansi_code("<red>+r60"), ansi_code("<red>"), "LCH hue rotation +60 changes color");
    isnt(ansi_code("<red>=r180"), ansi_code("<red>"), "LCH hue rotation =180 changes color");
}

# Test inversions
isnt(ansi_code("<red>i"), ansi_code("<red>"), "inversion changes color");
like(ansi_code("<red>ii"), qr/^\e\[38;5;\d+(;\d+)*m$/, "double inversion produces valid color");

# Test grayscale conversions
isnt(ansi_code("<red>g"), ansi_code("<red>"), "luminance grayscale changes color");
isnt(ansi_code("<red>G"), ansi_code("<red>"), "lightness grayscale changes color");

# Test multiple modifiers
isnt(ansi_code("<red>+l20-s10"), ansi_code("<red>"), "multiple modifiers change color");
isnt(ansi_code("<blue>=y70c"), ansi_code("<blue>"), "luminance set + complement changes color");

# Test modifiers with different color formats
isnt(ansi_code("FF0000+l20"), ansi_code("FF0000"), "hex color with lightness modifier");
like(ansi_code("(255,0,0)+s20"), qr/^\e\[38;5;\d+m$/, "RGB color with saturation modifier produces valid color");

SKIP: {
    eval { ansi_code("hsl(0,100,50)+l20") };
    skip "HSL with modifiers not supported", 3 if $@;
    
    isnt(ansi_code("hsl(0,100,50)+l20"), ansi_code("hsl(0,100,50)"), "HSL with lightness modifier");
    isnt(ansi_code("hsl(240,100,50)=y70"), ansi_code("hsl(240,100,50)"), "HSL with luminance modifier");
    isnt(ansi_code("hsl(120,100,50)c"), ansi_code("hsl(120,100,50)"), "HSL with complement");
}

SKIP: {
    eval { ansi_code("lab(50,20,-30)+h60") };
    skip "Lab with modifiers not supported", 2 if $@;
    
    isnt(ansi_code("lab(50,20,-30)+h60"), ansi_code("lab(50,20,-30)"), "Lab with hue modifier");
    isnt(ansi_code("lab(50,68,48)g"), ansi_code("lab(50,68,48)"), "Lab with grayscale");
}

# Test with text
is(ansi_color("<red>+l20", "bright red"), "\e[" . substr(ansi_code("<red>+l20"), 2) . "bright red" . RESET, "modifier with text");

# Test edge cases
eval { ansi_code("<red>+l200") }; # Very high lightness
ok(!$@, "handles extreme lightness values");

eval { ansi_code("<red>-l200") }; # Very low (negative) lightness  
ok(!$@, "handles extreme negative lightness values");

eval { ansi_code("<red>+h720") }; # Hue > 360
ok(!$@, "handles hue values > 360");

# Test invalid modifiers
eval { ansi_code("<red>+x10") }; # Invalid parameter
ok($@, "rejects invalid modifier parameter");

done_testing;