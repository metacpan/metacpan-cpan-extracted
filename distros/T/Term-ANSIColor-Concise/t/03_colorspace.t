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

# Test HSL color space
is(ansi_code("hsl(0,100,50)"), "\e[38;5;196m", "HSL red");
is(ansi_code("hsl(120,100,50)"), "\e[38;5;46m", "HSL green");
is(ansi_code("hsl(240,100,50)"), "\e[38;5;21m", "HSL blue");
is(ansi_code("hsl(60,100,50)"), "\e[38;5;226m", "HSL yellow");
is(ansi_code("hsl(300,100,50)"), "\e[38;5;201m", "HSL magenta");
is(ansi_code("hsl(180,100,50)"), "\e[38;5;51m", "HSL cyan");

rgb24 {
    is(ansi_code("hsl(0,100,50)"), "\e[38;2;255;0;0m", "HSL red 24bit");
    is(ansi_code("hsl(120,100,50)"), "\e[38;2;0;255;0m", "HSL green 24bit");
    is(ansi_code("hsl(240,100,50)"), "\e[38;2;0;0;255m", "HSL blue 24bit");
};

# Test Lab color space
SKIP: {
    eval { ansi_code("lab(50,68,48)") };
    skip "Lab color space not supported", 6 if $@;
    
    like(ansi_code("lab(50,68,48)"), qr/^\e\[38;5;\d+m$/, "Lab red");
    like(ansi_code("lab(87,-79,80)"), qr/^\e\[38;5;\d+m$/, "Lab green");
    like(ansi_code("lab(32,79,-108)"), qr/^\e\[38;5;\d+m$/, "Lab blue");
    
    rgb24 {
        like(ansi_code("lab(50,68,48)"), qr/^\e\[38;2;\d+;\d+;\d+m$/, "Lab red 24bit");
        like(ansi_code("lab(87,-79,80)"), qr/^\e\[38;2;\d+;\d+;\d+m$/, "Lab green 24bit");
        like(ansi_code("lab(32,79,-108)"), qr/^\e\[38;2;\d+;\d+;\d+m$/, "Lab blue 24bit");
    };
}

# Test LCH color space
SKIP: {
    eval { ansi_code("lch(50,130,0)") };
    skip "LCH color space not supported", 6 if $@;
    
    like(ansi_code("lch(50,130,0)"), qr/^\e\[38;5;\d+m$/, "LCH red");
    like(ansi_code("lch(87,119,136)"), qr/^\e\[38;5;\d+m$/, "LCH green");
    like(ansi_code("lch(32,133,306)"), qr/^\e\[38;5;\d+m$/, "LCH blue");
    
    rgb24 {
        like(ansi_code("lch(50,130,0)"), qr/^\e\[38;2;\d+;\d+;\d+m$/, "LCH red 24bit");
        like(ansi_code("lch(87,119,136)"), qr/^\e\[38;2;\d+;\d+;\d+m$/, "LCH green 24bit");
        like(ansi_code("lch(32,133,306)"), qr/^\e\[38;2;\d+;\d+;\d+m$/, "LCH blue 24bit");
    };
}

# Test color space with text
is(ansi_color("hsl(0,100,50)", "red text"), "\e[38;5;196mred text".RESET, "HSL with text");
is(ansi_color("hsl(120,100,50)", "green text"), "\e[38;5;46mgreen text".RESET, "HSL with text");

# Test invalid color space values
eval { ansi_code("hsl(361,100,50)") }; # Invalid hue > 360
ok(!$@, "HSL handles out of range hue");

eval { ansi_code("hsl(0,101,50)") }; # Invalid saturation > 100
ok(!$@, "HSL handles out of range saturation");

eval { ansi_code("hsl(0,100,101)") }; # Invalid lightness > 100
ok(!$@, "HSL handles out of range lightness");

done_testing;