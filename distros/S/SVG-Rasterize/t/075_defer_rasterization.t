#!perl -T
use strict;
use warnings;

# $Id: 075_defer_rasterization.t 6520 2011-04-23 03:19:09Z powergnom $

use Test::More tests => 14;

use SVG;
use Test::Exception;
use SVG::Rasterize;

sub defer_attribute {
    my $rasterize;
    my $svg;
    my $group;
    my $node;
    my $hook;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $group = $svg->group(id => 'g01');
    $node  = $group->text(id => 'te01');
    $node->tspan(id => 'ts01');
    $node  = $node->a(id => 'a01', 'xlink:href' => 'foo');
    $node->circle(id => 'ci01', r => 3);
    $group->circle(id => 'ci02', r => 3);
    @expected = ('svg', 'g01', 'te01', 'ts01', 'a01', 'ci01', 'ci02');
    $hook = sub {
	my ($rasterize, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    ok(!$state->defer_rasterization,
		'group does not defer rasterization');
	}
	if($state->node_attributes->{id} eq 'te01') {
	    is($state->defer_rasterization, 1,
		'text defers rasterization');
	}
	if($state->node_attributes->{id} eq 'ts01') {
	    is($state->defer_rasterization, 1,
		'tspan is deferred, too');
	}
	if($state->node_attributes->{id} eq 'a01') {
	    is($state->defer_rasterization, 1,
		'a is deferred, too');
	}
	if($state->node_attributes->{id} eq 'ci01') {
	    is($state->defer_rasterization, 1,
		'circle is deferred, too');
	}
	if($state->node_attributes->{id} eq 'ci02') {
	    ok(!$state->defer_rasterization,
		'circle outside text is not deferred');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);
    is(scalar(@expected), 0, 'all expected elements have been found');
}

defer_attribute;
