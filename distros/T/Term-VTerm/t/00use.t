#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use_ok( 'Term::VTerm' );
use_ok( 'Term::VTerm::Color' );
use_ok( 'Term::VTerm::GlyphInfo' );
use_ok( 'Term::VTerm::LineInfo' );
use_ok( 'Term::VTerm::Pos' );
use_ok( 'Term::VTerm::Rect' );
use_ok( 'Term::VTerm::Screen' );
use_ok( 'Term::VTerm::State' );

done_testing;
