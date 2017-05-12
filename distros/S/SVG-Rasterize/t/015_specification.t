#!perl -T
use strict;
use warnings;

# $Id: 015_specification.t 6485 2011-04-21 09:31:19Z powergnom $

use Test::More tests => 40;

use SVG;
use Test::Exception;
use SVG::Rasterize;
use SVG::Rasterize::Specification qw(:all);

sub _unload {
    # only works properly if only one module has been loaded
    my ($module) = @_;

    foreach(keys %SVG::Rasterize::Specification::CHILDREN) {
	if(ref($SVG::Rasterize::Specification::CHILDREN{$_})) {
	    $SVG::Rasterize::Specification::CHILDREN{$_} = $module;
	}
    }

    %SVG::Rasterize::Specification::ATTR_VAL   = ();
    %SVG::Rasterize::Specification::ATTR_HINTS = ();
}

sub load {
    is($SVG::Rasterize::Specification::CHILDREN{circle}, 'Shape',
       'Shape is not loaded');
    ok(!exists($SVG::Rasterize::Specification::ATTR_VAL{circle}),
       'attribute validation for circle does not exist');
    ok(!exists($SVG::Rasterize::Specification::ATTR_HINTS{circle}),
       'attribute hints for circle do not exist');

    SVG::Rasterize::Specification::_load_module('circle');
    is(ref($SVG::Rasterize::Specification::CHILDREN{circle}), 'HASH',
       'circle children is HASH reference');
    is($SVG::Rasterize::Specification::CHILDREN{circle}->{desc}, 1,
       'desc is child');
    is(ref($SVG::Rasterize::Specification::ATTR_VAL{circle}), 'HASH',
       'circle attribute validation is HASH reference');
    is($SVG::Rasterize::Specification::ATTR_VAL{circle}->{cx}->{optional},
       1, 'cx is optional');
    is(ref($SVG::Rasterize::Specification::ATTR_HINTS{circle}), 'HASH',
       'circle attribute hints is HASH reference');
    is($SVG::Rasterize::Specification::ATTR_HINTS{circle}->{fill}->{color},
       1, 'fill is color');
    is(spec_is_color('circle', 'stroke'), 1,
       'stroke is color by spec_is_color');
    
    _unload('Shape');
    is($SVG::Rasterize::Specification::CHILDREN{circle}, 'Shape',
       'Shape is not loaded');
    ok(!exists($SVG::Rasterize::Specification::ATTR_VAL{circle}),
       'attribute validation for circle does not exist');
    ok(!exists($SVG::Rasterize::Specification::ATTR_HINTS{circle}),
       'attribute hints for circle do not exist');
}

sub is_element {
    my $module;

    $module = $SVG::Rasterize::Specification::CHILDREN{svg};
    ok(spec_is_element('svg'), 'svg is element');
    ok(!spec_is_element('foo'), 'foo is no element');
    _unload($module);
}

sub has_child {
    my $module;

    $module = $SVG::Rasterize::Specification::CHILDREN{g};
    ok(spec_has_child('g', 'circle'), 'g has child circle');
    ok(!spec_has_child('g', 'foo'), 'g has no child foo');
    _unload($module);
    is($SVG::Rasterize::Specification::CHILDREN{circle}, 'Shape',
       'Shape is not loaded');

    $module = $SVG::Rasterize::Specification::CHILDREN{rect};
    ok(!spec_has_child('rect', 'bar'), 'rect has no child bar');
    ok(spec_has_child('rect', 'animate'), 'rect has child animate');
    _unload($module);

    $module = $SVG::Rasterize::Specification::CHILDREN{desc};
    ok(!spec_has_child('desc', 'polyline'), 'desc has child polyline');
    _unload($module);
}

sub has_pcdata {
    is(spec_has_pcdata('text'), 1, 'text has pcdata');
    is(spec_has_pcdata('textPath'), 1, 'textPath has pcdata');
    is(spec_has_pcdata('tspan'), 1, 'tspan has pcdata');
    is(spec_has_pcdata('title'), 1, 'title has pcdata');
    is(spec_has_pcdata('a'), 1, 'a has pcdata');
    is(spec_has_pcdata('g'), 0, 'g has no pcdata');
}

sub has_attribute {
    my $module;

    $module = $SVG::Rasterize::Specification::CHILDREN{g};
    is(spec_has_attribute('g', 'font-size'), 1, 'g has font-size');
    is(spec_has_attribute('g', 'foo'), 0, 'g has no attribute foo');
    ok(!defined(spec_has_attribute('bar', 'foo')),
       'bar cannot be asked for attributes');
    _unload($module);
}

sub attribute_validation {
    my $module;
    my $spec;
    
    $module = $SVG::Rasterize::Specification::CHILDREN{g};
    $spec   = spec_attribute_validation('g');
    ok(defined($spec), 'spec defined');
    is(ref($spec), 'HASH', 'spec is hash reference');
    ok(exists($spec->{stroke}), 'has spec for stroke');
    ok(exists($spec->{stroke}->{type}), 'has type spec for stroke');
    _unload($module);
}

sub is_length {
    my $module;
    
    $module = $SVG::Rasterize::Specification::CHILDREN{line};
    is(spec_is_length('line', 'x1'), 1, 'x1 is length on line');
    is(spec_is_length('line', 'stroke'), 0,
       'stroke-width is no length on line');
    ok(!defined(spec_is_length('baz', 'font-size')),
       'font-size cannot be checked for length on baz');
    _unload($module);
}

sub is_color {
    my $module;
    
    $module = $SVG::Rasterize::Specification::CHILDREN{text};
    is(spec_is_color('text', 'stroke'), 1, 'stroke is color on text');
    is(spec_is_color('text', 'stroke-width'), 0,
       'stroke-width is no color on text');
    ok(!defined(spec_is_color('baz', 'font-size')),
       'font-size cannot be checked for color on baz');
    _unload($module);
}

load;
is_element;
has_child;
has_pcdata;
has_attribute;
attribute_validation;
is_length;
is_color;
