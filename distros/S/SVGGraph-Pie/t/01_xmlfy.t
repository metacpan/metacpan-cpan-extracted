use strict;
use Test::More tests => 7;

use SVGGraph::Pie;

my $svggraph = SVGGraph::Pie->new;
my $output1 = $svggraph->CreateGraph(
    {
	label => 'true',
	title => 'unittest',
    },
    [
	{value => 10, color => 'red',  label => 'data-1'},
	{value => 20, color => 'blue', label => 'data-2'},
    ]
);

like $output1, qr/height="500"/i, q(title 1);
like $output1, qr/title="unittest"/i, q(title 1);
like $output1, qr/width="500"/i, q(title 1);
like $output1, qr/<text.*>unittest/i, q(title 2);

my $output2 = $svggraph->CreateGraph(
    {
	imageheight => 300,
	imagewidth  => 300,
	centertop   => 130,
	centerleft  => 130,
	radius      => 50,
	borderwidth => 1,
	label => 'true',
    },
    [
	{value => 10, color => 'rgb(255,0,0)', label => 'data-3'},
	{value => 20, color => 'rgb(0,0,255)', label => 'data-4'},
    ]
);

like $output2, qr/height="300"/i, q(title 1);
like $output2, qr/title=""/i, q(title 1);
like $output2, qr/width="300"/i, q(title 1);
