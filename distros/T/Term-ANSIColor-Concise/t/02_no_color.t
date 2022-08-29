use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    for (grep /^ANSICOLOR|^COLORTERM$/, keys %ENV) {
	delete $ENV{$_};
    }
    $ENV{NO_COLOR} = "1";
}

use Term::ANSIColor::Concise qw(ansi_color ansi_color_24 ansi_code);

use constant {
    RESET => "",
};

sub rgb24(&) {
    my $sub = shift;
    local $Term::ANSIColor::Concise::RGB24 = 1;
    $sub->();
}

is(ansi_color("N", "text"), "text", "N - NOP");
is(ansi_color(";", "text"), "text", "; - NOP");

is(ansi_color("R", "text"), ""."text".RESET, "ansi_color");

is(ansi_color("ABCDEF", "text"), ""."text".RESET, "ansi_color_24");

is(ansi_color_24("ABCDEF", "text"), ""."text".RESET, "ansi_color_24");

{
    my $text = ansi_color("R", "AB") . "CD" . ansi_color("R", "EF");
    my $rslt = ansi_color("R", "AB") . ansi_color("B", "CD") . ansi_color("R", "EF");
    is(ansi_color("B", $text), $rslt, "nested");
}

{
    my $text = "AB" . ansi_color("B", "CD") . "EF";
    my $rslt = ansi_color("R", "AB") . ansi_color("B", "CD") . ansi_color("R", "EF");
    is(ansi_color("R", $text), $rslt, "nested 2");
}

{
    my $text = ansi_color("R", "ABCDEF");
    is(ansi_color("B", $text), $text, "nested/unchange");
}

is(ansi_code("EE334E"), "\e[38;5;197m", "hex24 (DeePink2)");
is(ansi_code("ABCDEF"), "\e[38;5;153m", "hex24");
is(ansi_code("#AABBCC"), "\e[38;5;146m", "hex24 with #");
is(ansi_code("#ABC"),    "\e[38;5;146m", "hex12");
is(ansi_code("(171,205,239)"), "\e[38;5;153m", "rgb");

is(ansi_code("#AAABBBCCC"), "\e[38;5;146m", "hex36 with #");
is(ansi_code("#AAAABBBBCCCC"), "\e[38;5;146m", "hex48 with #");

done_testing;
