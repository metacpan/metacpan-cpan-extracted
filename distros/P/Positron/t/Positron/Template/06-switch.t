#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    require_ok('Positron::Template');
}

# Tests of the switching mechanism

my $template = Positron::Template->new();

my $dom = [
    'div', { style => '{|: view_mode }'},
    [ 'h1', { style => '{| "full"}'}, 'Full title'],
    [ 'h2', { style => '{| "condensed"}'}, 'Condensed title'],
    [ 'h2', { style => '{| moon.phase}'}, 'Moon title'],
    [ 'h1', { style => '{|}'}, 'Default title'],
];
is_deeply(
    $template->process($dom, { view_mode => 'full'}), 
    ['div', {}, ['h1', {} , 'Full title']],
    "First case selected"
);

is_deeply(
    $template->process($dom, { view_mode => 'condensed'}), 
    ['div', {}, ['h2', {} , 'Condensed title']],
    "Second case selected"
);

is_deeply(
    $template->process($dom, { view_mode => 'half-full', moon => { phase => 'half-full' }}), 
    ['div', {}, ['h2', {} , 'Moon title']],
    "Comparison with complex expression"
);

is_deeply(
    $template->process($dom, { view_mode => 'default', moon => { phase => 'half-full' }}), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (env defined)"
);

is_deeply(
    $template->process($dom, { view_mode => 'default'}), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (env half defined)"
);

is_deeply(
    $template->process($dom, { view_mode => 'default', moon => { phase => 'half-full' }}), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (env defined)"
);

is_deeply(
    $template->process($dom, { view_mode => 'default'}), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (env half defined)"
);

is_deeply(
    $template->process($dom, { moon => { phase => 'half-full' }}), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (env other half defined)"
);

# edge cases:

# N.B.: both not defined -> ''
is_deeply(
    $template->process($dom, { }), 
    ['div', {}, ['h2', {} , 'Moon title']],
    "Matching case selected (both not defined)"
);

is_deeply(
    $template->process($dom, { view_mode => '', moon => { phase => '' } }), 
    ['div', {}, ['h2', {} , 'Moon title']],
    "Matching case selected (both are '')"
);

is_deeply(
    $template->process($dom, { view_mode => '', moon => { phase => 0 } }), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (0 != '')"
);

$dom->[1]->{style} = '{|: view_mode : "default" }';
is_deeply(
    $template->process($dom, { }), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (both not defined, but selector fallback)"
);

is_deeply(
    $template->process($dom, { view_mode => '', moon => { phase => '' } }), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (both are '', but selector fallback)"
);

$dom->[1]->{style} = '{|: view_mode }';
$dom->[4]->[1]->{style} = '{| moon.phase : "new" }';
is_deeply(
    $template->process($dom, { }), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (both not defined, but case fallback)"
);

is_deeply(
    $template->process($dom, { view_mode => '', moon => { phase => '' } }), 
    ['div', {}, ['h1', {} , 'Default title']],
    "Default case selected (both are '', but case fallback)"
);

# syntax errors:

done_testing;


