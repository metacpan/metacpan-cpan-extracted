#!perl -T
use strict;
use warnings;

# $Id: 045_rasterize_interface.t 6323 2010-06-25 09:26:13Z mullet $

use Test::More tests => 27;
use Test::Exception;

use SVG::Rasterize;
use SVG;

sub svg_rasterize {
    my $rasterize;
    my $svg;

    $rasterize = SVG::Rasterize->new;
    throws_ok(sub { $rasterize->rasterize }, qr/svg/, 'blank rasterize');
    throws_ok(sub { $rasterize->rasterize(svg => undef) },
	      qr/svg.*SVG\:\:Rasterize|SVG\:\:Rasterize.*svg/,
	      'invalid svg');
    # more input validation

    $rasterize = SVG::Rasterize->new(width => 400, height => 300);
    is($rasterize->width, 400, 'width before rasterize');
    is($rasterize->height, 300, 'height before rasterize');
    $svg       = SVG->new;
    $rasterize->rasterize(svg => $svg);
    is($rasterize->width, 400, 'width after rasterize');
    is($rasterize->height, 300, 'height after rasterize');
    $rasterize->rasterize(svg => $svg, width => 600, height => 100);
    is($rasterize->width, 400, 'width after rasterize');
    is($rasterize->height, 300, 'height after rasterize');

    is($rasterize->engine->width, 600, 'engine width');
    is($rasterize->engine->height, 100, 'engine height');
}

sub engine_args {
    my $rasterize;
    my $svg;

    $rasterize = SVG::Rasterize->new(width => 10, height => 20);
    $svg       = SVG->new;
    $rasterize->rasterize(svg => $svg);
    is($rasterize->engine->width, 10, 'engine width from attribute');
    is($rasterize->engine->height, 20, 'engine height from attribute');

    $rasterize->rasterize(svg => $svg, width => 11, height => 21);
    is($rasterize->engine->width, 11, 'engine width from parameter');
    is($rasterize->engine->height, 21, 'engine height from parameter');

    $rasterize->rasterize(svg => $svg, width => 11, height => 21,
			  engine_args => {width => 12, height => 22});
    is($rasterize->engine->width, 12, 'engine width from engine_args');
    is($rasterize->engine->height, 22, 'engine height from engine_args');
}

sub child_nodes_by_rasterize {
    my $rasterize;
    my $svg;
    my $node;
    my @expected;

    # control
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01');
    $svg->group(id => 'g02');
    @expected = ('svg', 'g01', 'g02');
    $rasterize->before_node_hook(sub {
	my ($rasterize, %state_args) = @_;
	is($state_args{node_attributes}->{id}, shift(@expected),
	   'node name');

	if($state_args{node_attributes}->{id} eq 'svg') {
	    my $child_nodes = $state_args{child_nodes};
	    is(ref($child_nodes), 'ARRAY', 'child_nodes is ARRAY');
	    is(@$child_nodes, 2, '2 child nodes');
	}
	return %state_args;
    });
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;

	if($state->node_attributes->{id} eq 'svg') {
	    # dirty!
	    is(@{$state->{child_nodes}}, 2, '2 child nodes in state');
	}
    });
    $rasterize->rasterize(svg => $svg);

    # removal of child in before_node_hook
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01');
    $svg->group(id => 'g02');
    @expected = ('svg', 'g01', 'g02');
    $rasterize->before_node_hook(sub {
	my ($rasterize, %state_args) = @_;
	my $attr        = $state_args{node_attributes};
	my $child_nodes = $state_args{child_nodes};
	is($attr->{id}, shift(@expected), 'expected id');

	if($attr->{id} eq 'svg') {
	    is(ref($child_nodes), 'ARRAY', 'child_nodes is ARRAY');
	    is(@$child_nodes, 2, '2 child nodes');
	    pop(@$child_nodes);
	}

	return %state_args;
    });
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;

	if($state->node_attributes->{id} eq 'svg') {
	    # dirty!
	    is(@{$state->{child_nodes}}, 1, '1 child node in state');
	}
    });
    $rasterize->rasterize(svg => $svg);
}

svg_rasterize;
engine_args;
child_nodes_by_rasterize;
