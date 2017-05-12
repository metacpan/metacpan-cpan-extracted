#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 20;

use Pinwheel::TagSelect;


# Content selection
{
    my ($s, $fn);

    $fn = sub {
        [map { $_->string_value } $s->select(shift, \@_)->get_nodelist]
    };

    $s = Pinwheel::TagSelect->new();
    $s->read('<div><p id="a">hi <em>there</em></p><p id="b">foo</p></div>');
    is_deeply(&$fn('p'), ['hi there', 'foo']);
    is_deeply(&$fn('p#a'), ['hi there']);
    is_deeply(&$fn('p#b'), ['foo']);

    $s = Pinwheel::TagSelect->new();
    $s->read('<div><p id="x">a</p><p class="y">b</p></div>');
    is_deeply(&$fn('p[id=?]', 'x'), ['a']);
    is_deeply(&$fn('p[class=?]', 'y'), ['b']);
    is_deeply(&$fn('p#?', 'x'), ['a']);
    is_deeply(&$fn('p.?', 'y'), ['b']);
}

# Namespaces
{
    my ($s, $fn);

    $fn = sub {
        [map { $_->string_value } $s->select(shift, \@_)->get_nodelist]
    };

    $s = Pinwheel::TagSelect->new();
    $s->read('<div xmlns:x="a"><p>One</p><x:p>Two</x:p><x:a>Three</x:a></div>');
    is_deeply(&$fn('x|p'), ['Two']);

    $s = Pinwheel::TagSelect->new();
    $s->read('<div xmlns:x="a"><p x:n="1">One</p><p x:n="2">Two</p></div>');
    is_deeply(&$fn('p[x|n="1"]'), ['One']);
}

# Value substitution
{
    my ($s, $fn);

    $fn = sub {
        [map { $_->string_value } $s->select(shift, \@_)->get_nodelist]
    };

    $s = Pinwheel::TagSelect->new();
    $s->read('<div><p id="x">a</p><p class="y">b</p></div>');
    is_deeply(&$fn('p#?', 'x'), ['a']);
    is_deeply(&$fn('p.?', 'y'), ['b']);
    is_deeply(&$fn('p[id=?]', 'x'), ['a']);
}


# Default XML namespaces
{
    my ($xpc, $s, $fn);

    $fn = sub {
        [map { $_->string_value } $s->select(shift, \@_)->get_nodelist]
    };

    $s = Pinwheel::TagSelect->new();
    $s->read('<root xmlns="r"><a>text</a></root>');
    is_deeply(&$fn('a'), ['text']);
}

# Duplicate node removal (XML::LibXML only)
SKIP: {
    skip '_make_list_unique only applies to XML::LibXML', 4
	unless $INC{'XML/LibXML.pm'};

    my $s = Pinwheel::TagSelect->new();
    $s->read('<root xmlns="r"><a>text</a></root>');
    my $nodes = $s->select('a');

    is($nodes->size, 1);
    @$nodes = (@$nodes, @$nodes, @$nodes);
    is($nodes->size, 3);
    my $warned = 0;
    {
	local $SIG{__WARN__} = sub { ++$warned };
	Pinwheel::TagSelect::_make_list_unique($nodes);
    }
    is($nodes->size, 1);
    is($warned, 1);
}

# XPath instead of pseuso-css-to-xpath
{
    my ($s, $fn);

    $fn = sub {
        [map { $_->string_value } $s->select(shift, \@_)->get_nodelist]
    };

    $s = Pinwheel::TagSelect->new();
    $s->read('<div><p id="a">hi <em>there</em></p><p id="b">foo</p></div>');
    is_deeply(&$fn('//p'), ['hi there', 'foo']);
    is_deeply(&$fn('/p'), []);
    is_deeply(&$fn('//p[./em]'), ['hi there']);
}

