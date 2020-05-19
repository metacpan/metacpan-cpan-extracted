# -*- perl -*-

# t/04.colour.t - terminal coloured message

use Test::More qw( no_plan );
use strict;
use warnings;
use utf8;

BEGIN { use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" ); }

my $m = Module::Generic->new(
    debug => 3,
    colour_open => "\{",
    colour_close => "\}",
);
is(
    $m->colour_parse( "Hello {style => 'b', color => 'red'}red everyone! This is {style => 'u', color => 'rgb(255250250)'}embedded{/}{/} text..." ),
    "Hello \e[38;5;224;1m\e[38;2;255;0;0;1mred everyone! This is \e[38;5;250;4m\e[38;2;255;250;250;4membedded\e[m\e[m\e[m\e[m text...",
    "Inline style: Hello \e[38;5;224;1m\e[38;2;255;0;0;1mred everyone! This is \e[38;5;250;4m\e[38;2;255;250;250;4membedded\e[m\e[m\e[m\e[m text..."
);

is(
    $m->colour_parse( "And {style => 'i|b', color => light_red, bgcolor => white}light red on white{/} {style => 'blink', color => yellow}and yellow text{/} ?" ),
    "And \e[38;5;224;48;5;255;3;1m\e[38;2;255;0;0;48;2;255;255;255;3;1mlight red on white\e[m\e[m \e[38;5;252;5m\e[38;2;255;255;0;5mand yellow text\e[m\e[m ?",
    "Inline style: And \e[38;5;224;48;5;255;3;1m\e[38;2;255;0;0;48;2;255;255;255;3;1mlight red on white\e[m\e[m \e[38;5;252;5m\e[38;2;255;255;0;5mand yellow text\e[m\e[m ?",
);

is(
    $m->coloured( 'bold white on red', "Bold white text on red background" ),
    "\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mBold white text on red background\e[m\e[m",
    "Coloured() style: \e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mBold white text on red background\e[m\e[m",
);

is(
    $m->colour_parse( "And {bold light white on red}light white\non red multi line{/} {underline green}underlined green text{/}" ),
    "And \e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1m\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mlight white\e[m
\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mon red multi line\e[m \e[38;5;28;4m\e[38;2;0;255;0;4munderlined green text\e[m\e[m",
    "Inline with multi line: And \e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1m\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mlight white\e[m\\n\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mon red multi line\e[m \e[38;5;28;4m\e[38;2;0;255;0;4munderlined green text\e[m\e[m",
);

is(
    $m->colour_parse( "Some {bold red on white}red on white. And {underline rgb( 0, 0, 255 )}underlined{/}{/} text..." ),
    "Some \e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mred on white. And \e[38;5;3;4m\e[38;2;0;0;255;4munderlined\e[m\e[m\e[m\e[m text...",
    "Inline style with rgb: Some \e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mred on white. And \e[38;5;3;4m\e[38;2;0;0;255;4munderlined\e[m\e[m\e[m\e[m text...",
);

is(
    $m->coloured( 'bold rgb(255, 0, 0) on white', "Some red on white text." ),
    "\e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mSome red on white text.\e[m\e[m",
    "Coloured() style with rgb: \e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mSome red on white text.\e[m\e[m",
);

is(
    $m->coloured( 'bold rgb(255, 0, 0, 0.5) on white', "Some red on white text with 50% alpha." ),
    "\e[38;5;237;48;5;255;1m\e[38;2;255;128;128;48;2;255;255;255;1mSome red on white text with 50% alpha.\e[m\e[m",
    "Coloured() style with rgba: \e[38;5;237;48;5;255;1m\e[38;2;255;128;128;48;2;255;255;255;1mSome red on white text with 50% alpha.\e[m\e[m",
);

$m->colour_open( '<' );
$m->colour_close( '>' );
is(
    $m->colour_parse( "Regular <something here>phrase</>" ),
    'Regular phrase',
    'Unknown style parameter -> no change',
);

