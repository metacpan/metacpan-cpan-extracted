#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use RTF::HTML::Converter::ansi;
use RTF::TEXT::Converter::ansi;
use RTF::HTML::Converter::charmap;
use RTF::TEXT::Converter::charmap;

ok( ( scalar RTF::HTML::Converter::ansi::data ) > 1,
    "RTF::HTML::Converter::ansi returns more than one entry" );
ok( ( scalar RTF::TEXT::Converter::ansi::data ) > 1,
    "RTF::TEXT::Converter::ansi returns more than one entry" );
ok( ( scalar RTF::HTML::Converter::charmap::data ) > 1,
    "RTF::HTML::Converter::charmap returns more than one entry" );
ok( ( scalar RTF::TEXT::Converter::charmap::data ) > 1,
    "RTF::TEXT::Converter::charmap returns more than one entry" );

ok( ( scalar RTF::HTML::Converter::ansi::data ) > 1,
    "RTF::HTML::Converter::ansi returns more than one entry a second time" );
ok( ( scalar RTF::TEXT::Converter::ansi::data ) > 1,
    "RTF::TEXT::Converter::ansi returns more than one entry a second time" );
ok( ( scalar RTF::HTML::Converter::charmap::data ) > 1,
    "RTF::HTML::Converter::charmap returns more than one entry a second time" );
ok( ( scalar RTF::TEXT::Converter::charmap::data ) > 1,
    "RTF::TEXT::Converter::charmap returns more than one entry a second time" );
