#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 71;

use PDF::Builder;

# Translate

my $pdf = PDF::Builder->new('-compress' => 'none');
my $gfx = $pdf->page->gfx();

$gfx->translate(72, 144);
like($pdf->stringify(), qr/1 0 0 1 72 144 cm/, q{translate(72, 144)});

# Rotate

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->rotate(65);
like($pdf->stringify, qr/0.42262 0.90631 -0.90631 0.42262 0 0 cm/, q{rotate(65)});

# Scale

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->scale(1.1, 2.5);
like($pdf->stringify, qr/1.1 0 0 2.5 0 0 cm/, q{scale(1.1, 2.5)});

# Skew

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->skew(15, 25);
like($pdf->stringify, qr/1 0.26795 0.46631 1 0 0 cm/, q{skew(15, 25)});

# Transform

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->transform(-translate => [20, 50],
	            -rotate    => 10,
		        -scale     => [1.5, 3],
		        -skew      => [10, -20]);
$gfx->transform(-translate => [20, 50],
	            -rotate    => 10,
		        -scale     => [1.5, 3],
		        -skew      => [10, -20]);
like($pdf->stringify, qr/1.3854 0.78142 -1.0586 2.8596 20 50 cm 1.3854 0.78142 -1.0586 2.8596 20 50 cm/, q{transform + transform});

# Relative Transform

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->transform(-translate => [20, 50],
	        	-rotate    => 10,
				-scale     => [1.5, 3],
				-skew      => [10, -20]);
$gfx->transform_rel(-translate => [10, 10],
	            	-rotate    => 10,
		    		-scale     => [2, 4],
		    		-skew      => [5, -10]);
like($pdf->stringify, qr/1.3854 0.78142 -1.0586 2.8596 20 50 cm 1.7193 4.0475 -5.7318 10.684 30 60 cm/, q{transform + transform_rel});

# Matrix

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->matrix(1.3854, 0.78142, -1.0586, 2.8596, 20, 50);
like($pdf->stringify, qr/1.3854 0.78142 -1.0586 2.8596 20 50 cm/, q{matrix});

# Save

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->save();
like($pdf->stringify, qr/q/, q{save});

# Restore

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->restore();
like($pdf->stringify, qr/Q/, q{restore});

# Named Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor('blue');
like($pdf->stringify(), qr/0 0 1 rg/, q{fillcolor('blue')});

# RGB Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor('#ff0000');  # red
like($pdf->stringify(), qr/1 0 0 rg/, q{fillcolor('#ff0000')});

# CMYK Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor('%ff000000');  # cyan
like($pdf->stringify, qr/1 0 0 0 k/, q{fillcolor('%ff000000')});

# HSV Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor('!ffffcccc3333');  # dark red color
like($pdf->stringify, qr/0.2 0.04 0.0426667 rg/, q{fillcolor('!ffffcccc3333')});

# L*a*b Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor('&abc');  # ? color
like($pdf->stringify, qr|/LabS cs 94.6667 -51.8545 -51.8545 sc|, q{fillcolor('&abc')});

# Grayscale Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor(0.5);  # medium gray
like($pdf->stringify, qr/0.5 g/, q{fillcolor(0.5)});

# pattern or shading space Fill Color TBD

# Legacy format RGB Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor(0, 0.5, 0.5);  # medium cyan
like($pdf->stringify, qr/0 0.5 0.5 rg/, q{fillcolor(0, 0.5, 0.5)});

# Legacy format CMYK Fill Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillcolor(0.5, 0.5, 0, 0);  # medium blue
like($pdf->stringify, qr/0.5 0.5 0 0 k/, q{fillcolor(0.5, 0.5, 0, 0)});

# indexed colorspace plus color-index Fill Color TBD
# custom colorspace plus parameter Fill Color TBD

# Named Stroke Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor('blue');
like($pdf->stringify(), qr/0 0 1 RG/, q{strokecolor('blue')});

# RGB Stroke Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor('#ff0000');  # red
like($pdf->stringify(), qr/1 0 0 RG/, q{strokecolor('#ff0000')});

# CMYK Stroke Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor('%ff000000');  # cyan
like($pdf->stringify, qr/1 0 0 0 K/, q{strokecolor('%ff000000')});

# HSV Stroke Color (note: 11 digits; 9 will be used)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor('!ffffcccc333');  # dark red color
like($pdf->stringify, qr/0.0124971 0.00249943 0.00266606 RG/, q{strokecolor('!ffffcccc333')});

# L*a*b Stroke Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor('&778899');  # ? color
like($pdf->stringify, qr|/LabS CS 81.3333 -52.0374 11.6854 SC|, q{strokecolor('&778899')});

# Grayscale Stroke Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor(1.7);  # white, after being clamped to 1.0 max
like($pdf->stringify, qr/1 G/, q{strokecolor(1.7)});

# pattern or shading space Stroke Color TBD

# Legacy format RGB Stroke Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor(1, 5, 0);  # yellow after Green clamped to max 1.0
like($pdf->stringify, qr/1 1 0 RG/, q{strokecolor(1, 5, 0)});

# Legacy format CMYK Stroke Color

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->strokecolor(0.5, 0.5, -1, 0);  # medium blue after Yellow clamped to 0
like($pdf->stringify, qr/0.5 0.5 0 0 K/, q{strokecolor(0.5, 0.5, -1, 0)});

# indexed colorspace plus color-index Stroke Color TBD
# custom colorspace plus parameter Stroke Color TBD

# Line Width

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->linewidth(8.125);
like($pdf->stringify, qr/8.125 w/, q{linewidth(8.125)});

# Line Cap Style

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->linecap(1);
like($pdf->stringify, qr/1 J/, q{linecap(1)});

# Line Join Style

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->linejoin(1);
like($pdf->stringify, qr/1 j/, q{linejoin(1)});

# Miter Limit

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->miterlimit(3);
like($pdf->stringify, qr/3 M/, q{miterlimit(3)});

# Line Dash (no args)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->linedash();
like($pdf->stringify, qr/\[ \] 0 d/, q{linedash()});

# Line Dash (1 arg)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->linedash(3);
like($pdf->stringify, qr/\[ 3 \] 0 d/, q{linedash(3)});

# Line Dash (2 args)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->linedash(2, 1);
like($pdf->stringify, qr/\[ 2 1 \] 0 d/, q{linedash(2, 1)});

# Line Dash (hash)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->linedash(-pattern => [15, 5, 3, 2], -shift => 8);
like($pdf->stringify, qr/\[ 15 5 3 2 \] 8 d/, q{linedash(-pattern => [15, 5, 3, 2], -shift => 8)});

# Flatness Tolerance

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->flatness(5);
like($pdf->stringify, qr/5 i/, q{flatness(5)});


##
## PATH CONSTRUCTION
##

# Horizontal Line

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 144);
$gfx->hline(288);
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 288 144 l S/, q{hline});

# Vertical Line

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 144);
$gfx->vline(288);
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 72 288 l S/, q{vline});

# Poly-Line (4 args, 1 line segment)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->poly(72, 144, 216, 288);
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 216 288 l S/, q{poly, four arguments});

# Poly-Line (6 args, 2 line segments)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->poly(72, 144, 216, 288, 100, 200);
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 216 288 l 100 200 l S/, q{poly, six arguments});

# Rectangle

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->rect(100, 200, 25, 50);
$gfx->stroke();
$gfx->rect(100, 200, 25, -50);
$gfx->stroke();
$gfx->rect(200, 300, 50, 75, 400, 800, 10, 15);
$gfx->stroke();
like($pdf->stringify, qr/100 200 25 50 re S 100 200 25 -50 re S 200 300 50 75 re 400 800 10 15 re S/, q{rect});

# XY Rectangle

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->rectxy(100, 200, 125, 250);
$gfx->stroke();
$gfx->rectxy(100, 200, 125, 150);
$gfx->stroke();
like($pdf->stringify, qr/100 200 25 50 re S 100 200 25 -50 re S/, q{rectxy});

# Curve

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 144);
$gfx->curve(100, 200, 125, 250, 144, 288);
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 100 200 125 250 144 288 c S/, q{curve});

# qbSpline

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(30, 60);
$gfx->qbspline(90, 120, 150, 180);
$gfx->stroke();
like($pdf->stringify, qr/30 60 m 70 100 110 140 150 180 c S/, q{qbspline});

# bSpline

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();
my @points = (20,40, 70,50, 115,40, 145,35, 145,45, 115,40, 70,5);

$gfx->move(30, 60);
$gfx->bspline(\@points);
$gfx->stroke();
like($pdf->stringify, qr/30 60 m 30 60 m 22.547 60.065 15.476 45.923 20 40 c 30.316 26.494 53.006 50.181 70 50 c 85.364 49.837 99.918 42.93 115 40 c 124.95 38.067 137.27 28.448 145 35 c 147.54 37.154 147.54 42.846 145 45 c 137.27 51.552 124.28 44.069 115 40 c 97.597 32.372 81.677 19.99 70 5 c S/, q{bspline});

# Arc (with move)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 144);
$gfx->arc(216, 288, 144, 72, 90, 180, 1);
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 216 360 m 197.09 360 178.36 358.14 160.89 354.52 c 143.42 350.9 127.55 345.6 114.18 338.91 c 100.8 332.23 90.198 324.29 82.961 315.55 c 75.725 306.82 72 297.46 72 288 c S/,
     q{arc, with move});

# Arc (without move)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 144);
$gfx->arc(216, 288, 144, 72, 90, 180, 0);
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 197.09 360 178.36 358.14 160.89 354.52 c 143.42 350.9 127.55 345.6 114.18 338.91 c 100.8 332.23 90.198 324.29 82.961 315.55 c 75.725 306.82 72 297.46 72 288 c S/,
     q{arc, without move});

# Pie

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->pie(216, 288, 100, 80, 30, 100);
$gfx->stroke();
like($pdf->stringify, qr/216 288 m 302.6 328 l 297.5 335.07 291.08 341.47 283.56 346.98 c 276.04 352.5 267.51 357.06 258.26 360.5 c 249.02 363.95 239.17 366.25 229.05 367.32 c 218.94 368.38 208.68 368.2 198.64 366.78 c h S/,
     q{pie(216,288, 100,80, 30,100)});

# Bogen (with move)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->bogen(72, 72, 216, 72, 72, 1);
$gfx->stroke();
like($pdf->stringify, qr/72 72 m 72 81.455 73.862 90.818 77.481 99.553 c 81.099 108.29 86.402 116.23 93.088 122.91 c 99.774 129.6 107.71 134.9 116.45 138.52 c 125.18 142.14 134.54 144 144 144 c 153.46 144 162.82 142.14 171.55 138.52 c 180.29 134.9 188.23 129.6 194.91 122.91 c 201.6 116.23 206.9 108.29 210.52 99.553 c 214.14 90.818 216 81.455 216 72 c S/,
     q{bogen, with move});

# Bogen (without move)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 72);
$gfx->bogen(72, 72, 216, 72, 72, 0);
$gfx->stroke();
like($pdf->stringify, qr/72 72 m 72 81.455 73.862 90.818 77.481 99.553 c 81.099 108.29 86.402 116.23 93.088 122.91 c 99.774 129.6 107.71 134.9 116.45 138.52 c 125.18 142.14 134.54 144 144 144 c 153.46 144 162.82 142.14 171.55 138.52 c 180.29 134.9 188.23 129.6 194.91 122.91 c 201.6 116.23 206.9 108.29 210.52 99.553 c 214.14 90.818 216 81.455 216 72 c S/,
     q{bogen, without move});

# Bogen (without move, outer)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 72);
$gfx->bogen(72, 72, 144, 144, 72, 0, 1);
$gfx->stroke();
like($pdf->stringify, qr/72 72 m 64.919 72 57.876 73.045 51.1 75.1 c 44.323 77.156 37.887 80.2 31.999 84.134 c 26.111 88.068 20.836 92.85 16.343 98.324 c 11.851 103.8 8.1906 109.9 5.4807 116.45 c 2.7707 122.99 1.0408 129.9 0.3467 136.94 c -0.3474 143.99 0.00195 151.1 1.3835 158.05 c 2.765 164.99 5.1635 171.7 8.5017 177.94 c 11.84 184.19 16.081 189.9 21.088 194.91 c 26.096 199.92 31.814 204.16 38.059 207.5 c 44.305 210.84 51.008 213.24 57.953 214.62 c 64.899 216 72.01 216.35 79.057 215.65 c 86.105 214.96 93.011 213.23 99.553 210.52 c 106.1 207.81 112.2 204.15 117.68 199.66 c 123.15 195.16 127.93 189.89 131.87 184 c 135.8 178.11 138.84 171.68 140.9 164.9 c 142.96 158.12 144 151.08 144 144 c S/,
     q{bogen, without move, with outer});

# Bogen (without move, inner, reverse)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 72);
$gfx->bogen(72, 72, 144, 144, 72, 0, 0, 1);
$gfx->stroke();
like($pdf->stringify, qr/72 72 m 81.455 72 90.818 73.862 99.553 77.481 c 108.29 81.099 116.23 86.402 122.91 93.088 c 129.6 99.774 134.9 107.71 138.52 116.45 c 142.14 125.18 144 134.54 144 144 c S/,
     q{bogen, without move, without outer, with reverse});

# Close Path

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 144);
$gfx->line(216, 288);
$gfx->line(360, 432);
$gfx->close();
$gfx->stroke();
like($pdf->stringify, qr/72 144 m 216 288 l 360 432 l h S/,
     q{close});

# End Path

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->move(72, 144);
$gfx->line(216, 288);
$gfx->endpath();
like($pdf->stringify, qr/72 144 m 216 288 l n/,
     q{endpath});

# Ellipse

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->ellipse(144, 216, 108, 36);
$gfx->stroke();

like($pdf->stringify, qr/252 216 m 252 220.73 249.21 225.41 243.78 229.78 c 238.35 234.14 230.4 238.11 220.37 241.46 c 210.34 244.8 198.43 247.45 185.33 249.26 c 172.23 251.07 158.18 252 144 252 c 129.82 252 115.77 251.07 102.67 249.26 c 89.567 247.45 77.661 244.8 67.632 241.46 c 57.604 238.11 49.649 234.14 44.221 229.78 c 38.794 225.41 36 220.73 36 216 c 36 211.27 38.794 206.59 44.221 202.22 c 49.649 197.86 57.604 193.89 67.632 190.54 c 77.661 187.2 89.567 184.55 102.67 182.74 c 115.77 180.93 129.82 180 144 180 c 158.18 180 172.23 180.93 185.33 182.74 c 198.43 184.55 210.34 187.2 220.37 190.54 c 230.4 193.89 238.35 197.86 243.78 202.22 c 249.21 206.59 252 211.27 252 216 c h S/,
     q{ellipse});

# Circle

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->circle(144, 216, 72);
$gfx->stroke();
like($pdf->stringify, qr/216 216 m 216 225.46 214.14 234.82 210.52 243.55 c 206.9 252.29 201.6 260.23 194.91 266.91 c 188.23 273.6 180.29 278.9 171.55 282.52 c 162.82 286.14 153.46 288 144 288 c 134.54 288 125.18 286.14 116.45 282.52 c 107.71 278.9 99.774 273.6 93.088 266.91 c 86.402 260.23 81.099 252.29 77.481 243.55 c 73.862 234.82 72 225.46 72 216 c 72 206.54 73.862 197.18 77.481 188.45 c 81.099 179.71 86.402 171.77 93.088 165.09 c 99.774 158.4 107.71 153.1 116.45 149.48 c 125.18 145.86 134.54 144 144 144 c 153.46 144 162.82 145.86 171.55 149.48 c 180.29 153.1 188.23 158.4 194.91 165.09 c 201.6 171.77 206.9 179.71 210.52 188.45 c 214.14 197.18 216 206.54 216 216 c h S/,
     q{circle});

# Horizontal Scale

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->hscale(105);
like($pdf->stringify, qr/105 Tz/, q{hscale(105)});

# Fill Path

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fill();
$gfx->close();
$gfx->stroke();
like($pdf->stringify, qr/f h S/, q{fill()});

# Fill Path (even-odd rule)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fill(1);
$gfx->close();
$gfx->stroke();
like($pdf->stringify, qr/f\* h S/, q{fill(1)});

# Fill and Stroke

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillstroke();
$gfx->close();
$gfx->stroke();
like($pdf->stringify, qr/B h S/, q{fillstroke()});

# Fill and Stroke (even-odd rule)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->fillstroke(1);
$gfx->close();
$gfx->stroke();
like($pdf->stringify, qr/B\* h S/, q{fillstroke(1)});

# Clipping Path

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->clip();
$gfx->close();
$gfx->stroke();
like($pdf->stringify, qr/W h S/, q{clip()});

# Clipping Path (even-odd rule)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->clip(1);
$gfx->close();
$gfx->stroke();
like($pdf->stringify, qr/W\* h S/, q{clip(1)});

# Character Spacing

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->charspace(2);
like($pdf->stringify, qr/2 Tc/, q{charspace(2)});

# Word Spacing

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->wordspace(2);
like($pdf->stringify, qr/2 Tw/, q{wordspace(2)});

# Text Leading

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->leading(14);
like($pdf->stringify, qr/14 TL/, q{leading(14)});

# Text Rendering Mode

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->render(4);
like($pdf->stringify, qr/4 Tr/, q{render(4)});

# Text Rise

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->rise(4);
like($pdf->stringify, qr/4 Ts/, q{rise(4)});

# Distance

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->distance(3, 4);
like($pdf->stringify, qr/3 4 Td/, q{distance(3, 4)});

# cr

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->cr();
$gfx->cr(12.5);
$gfx->cr(0);
$gfx->cr(-9);
like($pdf->stringify, qr/T\* 0 12.5 Td 0 0 Td 0 -9 Td/, q{cr() cr(12.5) cr(0) cr(-9)});

# nl

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->nl();
like($pdf->stringify, qr/T\*/, q{nl});

# nl(0)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->nl(0);
like($pdf->stringify, qr/T\*/, q{nl(0)});

# nl(width)

$pdf = PDF::Builder->new('-compress' => 'none');
$gfx = $pdf->page->gfx();

$gfx->nl(300);
like($pdf->stringify, qr/T\* \[-3000\] TJ/, q{nl(300)});

1;
