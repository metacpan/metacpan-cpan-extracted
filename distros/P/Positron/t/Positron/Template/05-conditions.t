#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    require_ok('Positron::Template');
}

# Tests of the condition processing mechanism

my $template = Positron::Template->new();
is_deeply(
    $template->process(['b', {}, ['br', {}]], {}), 
    ['b', {}, ['br', {}]], 
    "Non-template structure works"
);
is_deeply(
    $template->process(
        ['b', { style => '{?true}' }, ['br', {}]], 
        {'true' => 1}
    ),  ['b', {}, ['br', {}]],
    "Condition works for simple dom"
);
is_deeply(
    [$template->process(
        ['b', { style => '{?true}'}, ['br', {}]], 
        {'true' => 0}
    )],  [],
    "False condition removes tree"
);
is_deeply(
    [$template->process(
        ['b', { style => '{?true}'}, ['br', {}]], 
        {},
    )],  [],
    "Missing condition removes tree"
);
# Quantifiers
is_deeply(
    [$template->process(
        ['b', { style => '{?+true}'}, ['br', {}]], 
        {'true' => 1}
    )],  [['b', {}, ['br', {}]]],
    "+: true condition keeps all"
);
is_deeply(
    [$template->process(
        ['b', { style => '{?+true}'}, ['br', {}]], 
        {'true' => 0}
    )],  [['b', {}]],
    "+: false condition removes child"
);

is_deeply(
    [$template->process(
        ['b', { style => '{?-true}'}, ['br', {}]], 
        {'true' => 1}
    )],  [['br', {}]],
    "-: true condition removes parent"
);
is_deeply(
    [$template->process(
        ['b', { style => '{?-true}'}, ['br', {}]], 
        {'true' => 0}
    )],  [],
    "-: false condition removes tree"
);

is_deeply(
    [$template->process(
        ['b', { style => '{?*true}'}, ['br', {}]], 
        {'true' => 1}
    )],  [['b', {}, ['br', {}]]],
    "*: true condition keeps all"
);
is_deeply(
    [$template->process(
        ['b', { style => '{?*true}'}, ['br', {}]], 
        {'true' => 0}
    )],  [['br', {}]],
    "*: False condition removes parent"
);

# Same for !

is_deeply(
    $template->process(
        ['b', { style => '{!true}' }, ['br', {}]], 
        {'true' => 0}
    ),  ['b', {}, ['br', {}]],
    "!: Condition works for simple dom"
);
is_deeply(
    [$template->process(
        ['b', { style => '{!true}'}, ['br', {}]], 
        {'true' => 1}
    )],  [],
    "!: True condition removes tree"
);
is_deeply(
    [$template->process(
        ['b', { style => '{!true}'}, ['br', {}]], 
        {},
    )],  [['b', {}, ['br', {}]]],
    "!: Missing condition keeps all"
);
# Quantifiers
is_deeply(
    [$template->process(
        ['b', { style => '{!+true}'}, ['br', {}]], 
        {'true' => 0}
    )],  [['b', {}, ['br', {}]]],
    "!+: false condition keeps all"
);
is_deeply(
    [$template->process(
        ['b', { style => '{!+true}'}, ['br', {}]], 
        {'true' => 1}
    )],  [['b', {}]],
    "!+: true condition removes child"
);

is_deeply(
    [$template->process(
        ['b', { style => '{!-true}'}, ['br', {}]], 
        {'true' => 0}
    )],  [['br', {}]],
    "-: true condition removes parent"
);
is_deeply(
    [$template->process(
        ['b', { style => '{!-true}'}, ['br', {}]], 
        {'true' => 1}
    )],  [],
    "!-: true condition removes tree"
);

is_deeply(
    [$template->process(
        ['b', { style => '{!*true}'}, ['br', {}]], 
        {'true' => 0}
    )],  [['b', {}, ['br', {}]]],
    "!*: false condition keeps all"
);
is_deeply(
    [$template->process(
        ['b', { style => '{!*true}'}, ['br', {}]], 
        {'true' => 1}
    )],  [['br', {}]],
    "!*: True condition removes parent"
);

# Complex expressions

is_deeply(
    $template->process(
        ['b', { style => '{? map.list }' }, ['br', {}]],
        {'map' => { list => [1, 2, 3]}}
    ),  ['b', {}, ['br', {}]],
    "Full list under hash lookup"
);
is_deeply(
    [$template->process(
        ['b', { style => '{? map.list }'}, ['br', {}]],
        {'map' => { list => [] }}
    )],  [],
    "Empty list under hash lookup"
);
is_deeply(
    [$template->process(
        ['b', { style => '{? map.list }'}, ['br', {}]],
        { 'map' => { none => 1 }},
    )],  [],
    "Missing map lookup removes tree"
);

done_testing;


