#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Test::More;
use Log::Any::Adapter 'TAP';

use_ok( 'OpenGL::Sandbox::V1::FTGLFont' ) or BAIL_OUT;

my $mmap= OpenGL::Sandbox::MMap->new("$FindBin::Bin/data/font/SquadaOne-Regular.ttf");
my $font= new_ok( 'OpenGL::Sandbox::V1::FTGLFont', [ data => $mmap ], '$font' );
is( $font->ascender,             21, 'ascender' );
is( $font->descender,            -5, 'descender' );
is( int($font->line_height),     25, 'line_height' );
is( int($font->advance("Test")), 36, 'advance("Test")' );
is( $font->face_size(40),        40, 'change face_size to 40' );
is( $font->ascender,             35, 'ascender' );
is( $font->descender,            -8, 'descender' );
is( int($font->line_height),     42, 'line_height' );
is( int($font->advance("Test")), 61, 'advance("Test")' );

done_testing;