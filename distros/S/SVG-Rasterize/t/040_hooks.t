#!perl -T
use strict;
use warnings;

use Test::More tests => 12;

use SVG;
use Test::Exception;
use SVG::Rasterize;

sub tree_traversal {
    my $rasterize;
    my $svg;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->group(id => 'foo')->group(id => 'bar')->line
	(x1 => 0, y1 => 100, x2 => 50, y2 => 140, id => 'baz');
    @expected = ('svg', 'g', 'g', 'line');
    $rasterize->before_node_hook(sub {
	my ($rasterize, %state_args) = @_;
	is($state_args{node_name}, shift(@expected), 'node name');
	return %state_args;
    });
    $rasterize->rasterize(svg => $svg);
    is(scalar(@expected), 0, 'all used up');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->group(id => 'foo')->group(id => 'bar')->line
	(x1 => 0, y1 => 100, x2 => 50, y2 => 140, id => 'baz');
    @expected = (undef, 'foo', 'bar', 'baz');
    $rasterize->before_node_hook(sub {
	my ($rasterize, %state_args) = @_;
	is($state_args{node_attributes}->{id}, shift(@expected),
	   'node name');
	return %state_args;
    });
    $rasterize->rasterize(svg => $svg);
    is(scalar(@expected), 0, 'all used up');

    lives_ok(sub { $rasterize->before_node_hook(undef) }, 'unset hook');
    ok(!defined($rasterize->{before_node_hook}), 'unset hook worked');
}

tree_traversal;
