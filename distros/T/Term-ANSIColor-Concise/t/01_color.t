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

is(ansi_color("N", "text"), "text", "N - NOP");
is(ansi_color(";", "text"), "text", "; - NOP");

is(ansi_color("R", "text"), "\e[31m"."text".RESET, "ansi_color");

is(ansi_color("R", "1\n2\n"), "\e[31m1".RESET."\n\e[31m2".RESET."\n", "multi-line");

is(ansi_color("R", "1\r2\n"), "\e[31m1".RESET."\r\e[31m2".RESET."\n", "carriage return");

is(ansi_color("ABCDEF", "text"), "\e[38;5;153m"."text".RESET, "ansi_color, 24bit");

is(ansi_color_24("ABCDEF", "text"), "\e[38;2;171;205;239m"."text".RESET, "ansi_color_24");

{
    my $text = ansi_color("R", "AB") . "CD" . ansi_color("R", "EF");
    my $rslt = ansi_code("U") . ansi_color("R", "AB") . ansi_code("U") . "CD" . ansi_color("R", "EF");
    is(ansi_color("U", $text), $rslt, "nested");
}

{
    my $text = "AB" . ansi_color("B", "CD") . "EF";
    my $rslt = ansi_code("U") . "AB" . ansi_color("B", "CD") . ansi_code("U") . "EF" . RESET;
    is(ansi_color("U", $text), $rslt, "nested 2");
}

{
    my $text = ansi_color("R", "ABCDEF");
    my $rslt = ansi_code("U") . $text;
    is(ansi_color("U", $text), $rslt, "nested 3");
}

TODO: {

local $TODO = "\$RGB24 does not update cached data.";

local $Term::ANSIColor::Concise::RGB24 = 1;
is(ansi_color("ABCDEF", "text"), "\e[38;2;171;205;239m"."text".RESET, "ansi_color (RGB24=1)");

}

{

local $Term::ANSIColor::Concise::LINEAR_256 = 1;

is(ansi_code("R"), "\e[31m", "color name");
is(ansi_code("W/R"), "\e[37;41m", "background");
{
    local $Term::ANSIColor::Concise::SPLIT_ANSI = 1;
    is(ansi_code("W/R"), "\e[37m\e[41m", "background (SPLIT_ANSI)");
}
is(ansi_code("RDPIUFQSHX"), "\e[31;1;2;3;4;5;6;7;8;9m", "effect");

is(ansi_code("ABCDEF"), "\e[38;5;152m", "hex24");
rgb24 {
    is(ansi_code("ABCDEF"), "\e[38;2;171;205;239m", "hex24 24bit");
};

is(ansi_code("~D~P~I~U~F~Q~S~H~X"), "\e[21;22;23;24;25;26;27;28;29m", "negate effect");

# underline style
{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is(ansi_code("U:3"), "\e[4:3m", "underline style");
    is(ansi_code("u:3"), "\e[4:3m", "underline style in lower case");
    is(ansi_code("U:0"), "\e[4:0m", "no underline by style");
    is(ansi_code("U"),   "\e[4m",   "plain underline stays");
    is(ansi_code("X:2"), "\e[9:2m", "style of another effect");
    is(ansi_code("DU:3"), "\e[1;4:3m", "underline style with an effect");
    is(ansi_code("U:3R"), "\e[4:3;31m", "underline style with a color");
    is(ansi_code("U:3;555"), "\e[4:3;38;5;231m", "style and a color in digits");
    is(ansi_code("U:3555"), "\e[4:3555m", "digits belong to the style");
    is(ansi_code("U:"),     "\e[4:m",     "colon only");
    is(ansi_code("U:::3"),  "\e[4:::3m",  "empty values");
    is(ansi_code("U:3:1"),  "\e[4:3:1m",  "two values");
    is(ansi_color("U:3", "AB"), "\e[4:3m" . "AB" . RESET, "ansi_color with a style");
    is(ansi_color("U:3", "A" . ansi_color("R", "B") . "C"),
       "\e[4:3m" . "A" . "\e[31m" . "B" . RESET . "\e[4:3m" . "C" . RESET,
       "nested in a style");
    is_deeply(\@warn, [], "no warning from the style");
    for my $spec (qw(~U:3 R:3 Z:1 N:1)) {
        ok(!eval { ansi_code($spec); 1 }, "$spec is an error");
    }
}

is(ansi_code("#AABBCC"), "\e[38;5;146m", "hex24 with #");
is(ansi_code("#ABC"),    "\e[38;5;146m", "hex12");
rgb24 {
    is(ansi_code("#AABBCC"), "\e[38;2;170;187;204m", "hex24 24bit");
    is(ansi_code("#ABC"),    "\e[38;2;170;187;204m", "hex12 24bit");
};

is(ansi_code("(171,205,239)"), "\e[38;5;152m", "rgb");
rgb24 {
    is(ansi_code("(171,205,239)"), "\e[38;2;171;205;239m", "rgb 24bit");
    is(ansi_code("(1,2,3)"), "\e[38;2;1;2;3m", "rgb 24bit");
};

}


is(ansi_code("EE334E"), "\e[38;5;197m", "hex24 (DeePink2)");
is(ansi_code("ABCDEF"), "\e[38;5;153m", "hex24");
is(ansi_code("#AABBCC"), "\e[38;5;146m", "hex24 with #");
is(ansi_code("#ABC"),    "\e[38;5;146m", "hex12");
is(ansi_code("(171,205,239)"), "\e[38;5;153m", "rgb");

is(ansi_code("#AAABBBCCC"), "\e[38;5;146m", "hex36 with #");
is(ansi_code("#AAAABBBBCCCC"), "\e[38;5;146m", "hex48 with #");


is(ansi_code("DK/544"), "\e[1;30;48;5;224m", "256 color");
is(ansi_code("//DK///544"), "\e[1;30;48;5;224m", "multiple /");
is(ansi_code("L25/L00"), "\e[38;5;231;48;5;16m", "L25/L00 == 555/000");
is(ansi_code("L01/L24"), "\e[38;5;232;48;5;255m", "grey scale");
if ($Term::ANSIColor::Concise::LINEAR_GRAY) {
    is(ansi_code("CCCCCC"), "\e[38;5;251m", "hex to grey scale map");
} else {
    is(ansi_code("CCCCCC"), "\e[38;5;252m", "hex to grey scale map");
}
is(ansi_code("FFFFFF/000000"), "\e[38;5;231;48;5;16m", "hex, all 0/1");

is(ansi_code("DK/544E"), "\e[1;30;48;5;224m" . "\e[K", "E");
is(ansi_code("DK/544{EL}"), "\e[1;30;48;5;224m" . "\e[K", "{EL}");
is(ansi_code("DK/E544"), "\e[1;30m"."\e[K"."\e[48;5;224m" , "E");
is(ansi_code("DK/{EL}544"), "\e[1;30m"."\e[K"."\e[48;5;224m" , "{EL}");
is(ansi_code("{SGR}"), "\e[m", "{SGR}");
is(ansi_code("{SGR1;30;48;5;224}"), "\e[1;30;48;5;224m", "{SGR...}");
is(ansi_code("{SGR(1,30,48,5,224)}"), "\e[1;30;48;5;224m", "{SGR(...)}");
is(ansi_code("{SGR4:2}"), "\e[4:2m", "{SGR...} with a colon");
is(ansi_code("{SGR(4:2,1)}"), "\e[4:2;1m", "{SGR(...)} with a colon");
is(ansi_code("{SGR4:3;58:2::255:0:0}"), "\e[4:3;58:2::255:0:0m", "{SGR...} with empty values");
is(ansi_color("{SGR4:2}", "AB"), "\e[4:2m" . "AB" . RESET, "ansi_color with {SGR...} and a colon");
for my $spec ("{CUP1:2}", "{EL(0:1)}") {
    eval { ansi_code($spec) };
    like($@, qr/Color spec error: "\Q$spec\E"/, "$spec: a colon is only for SGR");
}

like(ansi_end("DK/544E"), qr/^\e\[?K/, "E before RESET");
like(ansi_end("DK/544{EL}"), qr/^\e\[?K/, "{EL} before RESET");

is(ansi_code("<moccasin>"), "\e\[38;5;223m",
   "color name (<moccasin>)");

rgb24 {
    is(ansi_code("<moccasin>"), "\e[38;2;255;228;181m",
       "<moccasin> 24bit");
};

is(ansi_code("<fuchsia>"), "\e\[38;5;201m", "color name (<fuchsia>)");

SKIP: {
    eval {
	is(ansi_code("<fuscia>"), "\e\[38;5;201m", "color name (<fuscia>)");
    };
    skip $@ =~ s/\)\K.*//r, 1 if $@;
}

done_testing;

sub ansi_end {
    my $color = shift;
    my($s, $e) = Term::ANSIColor::Concise::ansi_pair($color);
    $e;
}
