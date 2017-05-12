#!perl -T
use strict;
use warnings;

use Test::More tests => 11;

use SVG;
use Test::Exception;
use SVG::Rasterize;
use SVG::Rasterize::Specification qw(:all);

sub children {
    my $rasterize;
    my $svg;
    my $hook;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->g(id => 'g01')->circle(id => 'c02', r => 5);
    @expected = ('svg', 'g01', 'c02');
    $hook = sub {
	my (undef, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $svg->circle(id => 'c03', r => 5)->g(id => 'g04');
    $rasterize->start_node_hook(undef);
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Element 'g' is not a valid child of element 'circle'./,
	      'Group below circle');
}

sub attributes {
    my $rasterize;
    my $svg;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->g(id => 'g01')->circle(id => 'c02', r => 5, foo => 'bar');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/foo/,
	      'circle attribute foo');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->g(id => 'g01', width => '300');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/width/,
	      'group attribute width');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->g(id => 'g01', transform => 'foo(1.0, 4.5)');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/transform/,
	      'transform by foo');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->g(id => 'g01', transform => 'footranslate(1.0, 4.5)');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/transform/,
	      'transform by footranslate');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->svg(id => 'svg01', 'viewBox' => '1 2 3');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/viewBox/,
	      'invalid viewBox');

    # ID
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'foo:bar');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_name eq 'g') {
	    is($state->node_attributes->{id}, 'foo:bar',
	       "'foo:bar' is valid ID");
	}
    });
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'foo bar');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/id/,
	      "'foo bar' is invalid ID");
}

children;
attributes;
