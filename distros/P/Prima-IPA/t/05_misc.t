#! /usr/bin/perl
# $Id$

use strict;
use warnings;

use Prima::noX11;
use Prima::IPA qw(Misc);

use Test::More tests => 2;

my $i = Prima::Image-> create(
	width    => 4,
	height   => 4,
	type     => im::Byte,
	lineSize => 4, # must stay x4 for these tests!
	data     => 
		"\0\0\0\0" .
		"\xff\xff\xff\0" .
		"\xff\x00\xff\0" . 
		"\xff\xff\xff\0" 
);

my @h = histogram($i);
ok( ($h[0] == 8 and $h[-1] == 8), 'histogram');

my ( $r, $g, $b) = ( $i, $i-> dup, $i-> dup);
$g-> data( ~$g-> data); 
$b-> pixel(2,2,0xff);

my $comb = combine_channels( [$r,$g,$b], 'rgb');
my ( $R, $G, $B) = @{ split_channels( $comb, 'rgb') };
ok(
	($r->data eq $R->data) &&
	($g->data eq $G->data) &&
	($b->data eq $B->data),
	'split/combine channels'
);
