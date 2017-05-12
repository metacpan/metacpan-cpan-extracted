#!/usr/bin/env perl

use Test::More tests => 4;
use Carp;

use strict;
use warnings;
use SVG::Sparkline;

{
    my $w = SVG::Sparkline->new( Whisker => {values=>'++0++0--'} );
    unlike( "$w", qr/xmlns:svg=/, 'no xmlns:svg unless -allns' );
    unlike( "$w", qr/xmlns:xlink=/, 'no xmlns:xlink unless -allns' );
}

{
    my $w = SVG::Sparkline->new( Whisker => {values=>'++0++0--', -allns=>1} );
    like( "$w", qr/xmlns:svg=/, 'no xmlns:svg unless -allns' );
    like( "$w", qr/xmlns:xlink=/, 'no xmlns:xlink unless -allns' );
}



