#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::Terminal;

sub test_roundtrip
{
   my ( $string, $title ) = @_;

   my $st = String::Tagged::Terminal->parse_terminal( $string );

   is( $st->build_terminal, $string, "$title round-trip parses" );
}

test_roundtrip "Some plain text", 'plain text';

test_roundtrip "Some \e[1mbold\e[m text", 'bold text';
test_roundtrip "Some \e[4munder\e[m text", 'under text';
test_roundtrip "Some \e[3mitalic\e[m text", 'italic text';
test_roundtrip "Some \e[9mstrike\e[m text", 'strike text';
test_roundtrip "Some \e[5mblink\e[m text", 'blink text';
test_roundtrip "Some \e[7mreverse\e[m text", 'reverse text';

test_roundtrip "Some \e[11maltfont\e[m text", 'altfont text';

test_roundtrip "\e[31mred\e[m \e[32mgreen\e[m", 'fg basic colour text';
test_roundtrip "\e[91mhi-red\e[m",              'fg hi colour text';
test_roundtrip "\e[38:5:123mpalette\e[m",       'fg palette colour text';

test_roundtrip "\e[41mred\e[m \e[42mgreen\e[m", 'bg basic colour text';
test_roundtrip "\e[101mhi-red\e[m",             'bg hi colour text';

test_roundtrip "\e[73msuperscript\e[m \e[74msubscript\e[m", 'sub/superscript text';

test_roundtrip "\e]8;;http://example.com/\e\\Link here\e]8;;\e\\", 'OSC 8 hyperlink';

sub test_parsebuild
{
   my ( $inp, $out, $title ) = @_;

   my $st = String::Tagged::Terminal->parse_terminal( $inp );

   is( $st->build_terminal, $out, "$title parses and builds" );
}

# Various forms of reset
test_parsebuild "\e[1mX\e[0mY",  "\e[1mX\e[mY", 'SGR 0 reset';
test_parsebuild "\e[1mX\e[00mY", "\e[1mX\e[mY", 'SGR 00 reset';

# Other terminal escapes are not accepted
like( dies { String::Tagged::Terminal->parse_terminal( "Here\e[AThere" ) },
   qr/^Found an escape sequence that is not SGR at / );

# Unrecognised SGRs do not warn
ok( no_warnings { String::Tagged::Terminal->parse_terminal( "\e[6mXYZ" ) },
   'Unrecognised SGR codes do not warn' );

done_testing;
