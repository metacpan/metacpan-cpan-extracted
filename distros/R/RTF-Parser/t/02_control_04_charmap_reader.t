#!/usr/bin/perl

# We're checking that application_dir returns sensibly.

use strict;
use warnings;

use RTF::TEXT::Converter;
use RTF::HTML::Converter;

use Test::More tests => 8;

my $text_object = RTF::TEXT::Converter->new( output => \*STDOUT );
my $html_object = RTF::HTML::Converter->new( output => \*STDOUT );

# Test TEXT...
{
    my @char_map_data = $text_object->charmap_reader('char_map');
    is( $char_map_data[0], 'exclam		!',
        "Module charmap, first result correct" );
    is( $char_map_data[1], 'quotedbl	"',
        "Module charmap, second result correct" );
    my @ansi_data = $text_object->charmap_reader('ansi');
    is( $ansi_data[0], '00 ` ',      "Module ansi, first result correct" );
    is( $ansi_data[1], '01 &acute;', "Module ansi, second result correct" );
}

# Test HTML...
{
    my @char_map_data = $html_object->charmap_reader('char_map');
    is( $char_map_data[0], 'exclam		!',
        "Module charmap, first result correct" );
    is( $char_map_data[1], 'quotedbl	"',
        "Module charmap, second result correct" );
    my @ansi_data = $html_object->charmap_reader('ansi');
    is( $ansi_data[0], '00 ` ',      "Module ansi, first result correct" );
    is( $ansi_data[1], '01 &acute;', "Module ansi, second result correct" );
}
