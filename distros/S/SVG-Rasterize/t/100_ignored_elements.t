#!perl -T
use strict;
use warnings;

# $Id: 045_rasterize_interface.t 6323 2010-06-25 09:26:13Z mullet $

use Test::More tests => 9;
use Test::Exception;

use SVG::Rasterize;
use SVG;

sub comments {
    my $rasterize;
    my $svg;

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->comment('foo');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'comment in root');

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->g->comment('bar');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'comment in group');
}

sub ignored_elements {
    my $rasterize;
    my $svg;

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->desc->cdata('foo');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'desc element in root');

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->g->desc->cdata('bar');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'desc element in group');

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->title->cdata('foo');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'title element in root');

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->metadata->cdata('foo');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'metadata element in root');

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->g->metadata->cdata('bar');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'metadata element in group');

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->g->element('foo')->cdata('bar');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Element \'foo\' is not a valid child of element \'g\'\./,
	     'foo element in group throws error');

    $SVG::Rasterize::IGNORED_NODES{foo} = 1;
    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    $svg       = SVG->new;
    $svg->g->element('foo')->cdata('bar');
    lives_ok(sub { $rasterize->rasterize(svg => $svg) },
	     'IGNORED_NODES rescues foo element in group');
}

comments;
ignored_elements;

