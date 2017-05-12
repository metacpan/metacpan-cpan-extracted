#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    require_ok('Positron::Template');
}

# Tests of the loop processing mechanism

my $template = Positron::Template->new();
is_deeply(
    $template->process(['b', {}, ['br', {}]], {}), 
    ['b', {}, ['br', {}]], 
    "Non-template structure works"
);
is_deeply(
    $template->process(
        ['b', { style => '{@loop}'}, ['br', {}]], 
        {'loop' => [{}, {}]}
    ),  ['b', {}, ['br', {}], ['br', {}]],
    "Loop works for simple dom"
);
is_deeply(
    [$template->process(
        ['b', { style => '{@loop}'}, ['br', {}]], 
        {'loop' => []}
    )], [],
    "Empty loop"
);

is_deeply(
    $template->process(
        ['b', { style => '{@+loop}'}, ['br', {}]], 
        {'loop' => [{}, {}]}
    ),  ['b', {}, ['br', {}], ['br', {}]],
    "Loop works for simple dom (+ quant)"
);
is_deeply(
    [$template->process(
        ['b', { style => '{@+loop}'}, ['br', {}]], 
        {'loop' => []}
    )], [['b', { }]],
    "Empty loop (+ quant)"
);

is_deeply(
    [$template->process(
        ['b', { style => '{@-loop}'}, ['br', {}]], 
        {'loop' => [{}, {}]}
    )],  [['br', {}], ['br', {}]],
    "Loop works for simple dom (- quant)"
);
is_deeply(
    [$template->process(
        ['b', { style => '{@-loop}'}, ['br', {}]], 
        {'loop' => []}
    )], [],
    "Empty loop (- quant)"
);

is_deeply(
    [$template->process(
        ['b', { style => '{@*loop}'}, ['br', {}]], 
        {'loop' => [{}, {}]}
    )],  [['b', {}, ['br', {}]], ['b', {}, ['br', {}]]],
    "Loop works for simple dom (* quant)"
);
is_deeply(
    [$template->process(
        ['b', { style => '{@*loop}'}, ['br', {}]], 
        {'loop' => []}
    )], [],
    "Empty loop (* quant)"
);

# Environment chaining;

is_deeply(
    $template->process(
        ['b', { id => '{$text}', style => '{@loop}'}, ['br', { id => '{$text}'}]], 
        {text => '0', 'loop' => [{ text => 'a' }, { text => 'b' }]}
    ),  ['b', { id => '0'}, ['br', { id => 'a'}], ['br', {id => 'b'}]],
    "Environment chaining"
);

# Complex environments

is_deeply(
    $template->process(
        ['b', { style => '{@ map.list }'}, ['br', {}]],
        {'map' => { list => [1, 2], not_list => [] }},
    ),  ['b', {}, ['br', {}], ['br', {}]],
    "Loop lookup under hash"
);

is_deeply(
    [$template->process(
        ['b', { style => '{@ map.not_list }'}, ['br', {}]],
        {'map' => { list => [1, 2], not_list => [] }},
    )],  [],
    "Empty loop lookup under hash"
);

done_testing;


