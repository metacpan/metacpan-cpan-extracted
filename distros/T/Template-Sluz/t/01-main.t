#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz(extra => {
    hashref => {nested => {deep => 'found'}},
});

# -------------------------------------------------------------------
# Basic tests
# -------------------------------------------------------------------
sluz_test($sluz, 'Hello there',                             'Hello there',                 'Basic #1 - Static string');
sluz_test($sluz, '{$first}',                                'Scott',                       'Basic #2 - Basic variable');
sluz_test($sluz, '{$bogus_var}',                            '',                            'Basic #3 - Missing variable');
sluz_test($sluz, '{$cust.first}',                           'Scott',                       'Basic #5 - Hash Lookup');
sluz_test($sluz, '{$array.1}',                              'two',                         'Basic #6 - Array Lookup');
sluz_test($sluz, '{$array|count}',                          '3',                           'Basic #7 - Modifier on array');
sluz_test($sluz, '{$number + 3}',                           '18',                          'Basic #8 - Addition');
sluz_test($sluz, '{$number * $debug}',                      '15',                          'Basic #9 - Multiplication of two vars');
sluz_test($sluz, '{3}',                                     '3',                           'Basic #10 - Number literal');
sluz_test($sluz, '{"Scott"}',                               'Scott',                       'Basic #11 - String literal');
sluz_test($sluz, '{$x}',                                    '7',                           'Basic #12 - Single Character variable');
sluz_test($sluz, '{$array[1]}',                             'two',                         'Basic #13 - Array Lookup - PHP Syntax');
sluz_test($sluz, '{$cust["last"]}',                         'Baker',                       'Basic #14 - Hash Lookup - PHP Syntax');

# Default values
sluz_test($sluz, '{$last|default:\'123\'}',                 'Baker',                       'Basic #15 - Default - Not Used');
sluz_test($sluz, '{$zero|default:\'123\'}',                 '0',                           'Basic #16 - Default - Zero Not Used');
sluz_test($sluz, '{$empty_string|default:\'123\'}',         '123',                         'Basic #17 - Default - Empty String');
sluz_test($sluz, '{$null|default:\'123\'}',                 '123',                         'Basic #18 - Default - Null');
sluz_test($sluz, '{$bogus_var|default:"?*%.|"}',            '?*%.|',                       'Basic #19 - Default - non word char');

# Undefined variables with modifiers
sluz_test($sluz, '{$bogus_var|join}',                        '',                            'Basic #20 - Undefined var with array modifier');
sluz_test($sluz, '{$bogus_var|uc}',                          '',                            'Basic #21 - Undefined var with string modifier');
sluz_test($sluz, '{$bogus_var|count}',                       '',                            'Basic #22 - Undefined var with count modifier');
sluz_test($sluz, '{$bogus_var|substr:0,2}',                  '',                            'Basic #23 - Undefined var with string modifier with params');

# Error tests (croak via eval)
eval { $sluz->parse_string('{foo') };
like($@, qr/45821/, 'Basic #24 - Unclosed block');

eval { $sluz->parse_string('{$first') };
like($@, qr/45821/, 'Basic #25 - Unclosed block variable');

# Hash with default
sluz_test($sluz, '{$cust.first|default:\'Jason\'}'        , 'Scott'       , 'Basic #26 - Hash with default value                         , not used');
sluz_test($sluz, '{$cust.foo|default:\'Jason\'}'          , 'Jason'       , 'Basic #27 - Hash with default value                         , used');
sluz_test($sluz, '{$array}'                               , 'ARRAY'       , 'Basic #28 - Array used as a scalar');
sluz_test($sluz, '{$first|substr:2}'                      , 'ott'         , 'Basic #29 - Perl function with one param');
sluz_test($sluz, '{$first|substr:2, 2}'                   , 'ot'          , 'Basic #30 - Perl function with two params');
sluz_test($sluz, '{if !$cust.age}unknown{else}{$age}{/if}', 'unknown'     , 'Basic #31 - Negated hash lookup');
sluz_test($sluz, '{1.1234 + 2.3456}'                      , '3.469'       , 'Basic #32 - Simple math that returns floating point');
sluz_test($sluz, ''                                       , ''            , 'Basic #33 - Empty template');
sluz_test($sluz, ' '                                      , ' '           , 'Basic #34 - Whitespace only template');
sluz_test($sluz, '{$bogus_var + 3}'                       , '3'           , 'Basic #35 - Undefined var in numeric expression');
sluz_test($sluz, '{!$false}'                              , '1'           , 'Basic #36 - Standalone negated expression (false to true)');
sluz_test($sluz, '{!$true}'                               , ''            , 'Basic #37 - Standalone negated expression (true to false)');
sluz_test($sluz, '{$car}'                                 , 'Honda'       , 'Basic #38 - String variable set from hash');
sluz_test($sluz, '{$ltuae}'                               , '42'          , 'Basic #39 - Integer variable set from hash');
sluz_test($sluz, '{$milk|join:":"}'                       , 'goat:cow:soy', 'Basic #40 - Array set from hash');

# -------------------------------------------------------------------
# Custom/User functions
# -------------------------------------------------------------------
sluz_test($sluz, '{$word|truncate:3}',                      'cRa',                         'Custom function #1 - Modifier with param');
sluz_test($sluz, '{$last|truncate:4|truncate:2}',           'Ba',                          'Custom function #2 - Two modifiers with params');
sluz_test($sluz, '{$y|join_comma}',                         '2, 4, 6',                     'Custom function #3 - Function with default param');
sluz_test($sluz, '{$y|join_comma:9}',                       '29496',                       'Custom function #4 - Function with integer param');
sluz_test($sluz, '{$y|join_comma:"*"}',                     '2*4*6',                       'Custom function #5 - Function with string param');
sluz_test($sluz, '{$y|join_comma:"|"}',                     '2|4|6',                       'Custom function #6 - Function with string param pipe');
sluz_test($sluz, '{$y|join_comma:","}',                     '2,4,6',                       'Custom function #7 - Function with string param pipe comma');
sluz_test($sluz, '{$y|join_comma:"\'"}',                    "2'4'6",                       'Custom function #8 - Function with string param pipe single quote');
sluz_test($sluz, '{$y|join_comma:"; "}',                    "2; 4; 6",                     'Custom function #9 - Function with string param and space');
sluz_test($sluz, "{\$y|join_comma:\"\t\"}",                 "2\t4\t6",                     'Custom function #10 - Function with string param and tab');

# Built-in join modifier
sluz_test($sluz, '{$array|join}',                           'one, two, three',             'Built-in join #1 - default glue');
sluz_test($sluz, '{$array|join:" - "}',                     'one - two - three',           'Built-in join #2 - custom glue');
sluz_test($sluz, '{$array|join:","}',                       'one,two,three',               'Built-in join #3 - comma glue');

# -------------------------------------------------------------------
# Function blocks
# -------------------------------------------------------------------
sluz_test($sluz, '{hello_world()}',                         'Hello world',                 'Function #1 - Hello world');

is($sluz->parse_string('{return_false()}'), '0', 'Function #2 - Return false');

eval { $sluz->parse_string('{return_null()}') };
like($@, qr/18933/, 'Function #3 - Return null');

# -------------------------------------------------------------------
# Error blocks
# -------------------------------------------------------------------
eval { $sluz->parse_string('{junk}') };
like($@, qr/73467/, 'Error #1 - bare string');

eval { $sluz->parse_string('{junk(') };
like($@, qr/45821/, "Error #2 - string with action char");

eval { $sluz->parse_string('{$number + array}') };
like($@, qr/18933/, 'Error #3 - syntax error');

eval { $sluz->parse_string('{if debug}') };
like($@, qr/73467/, 'Error #4 - syntax error');

# -------------------------------------------------------------------
# Plain text tests
# -------------------------------------------------------------------
sluz_test($sluz, 'Scott',              'Scott',              'Plain text #1 - Static text');
sluz_test($sluz, '<div>Scott</div>',   '<div>Scott</div>',   'Plain text #2 - HTML');

# -------------------------------------------------------------------
# Bad block tests
# -------------------------------------------------------------------
sluz_test($sluz, ' {$first} ',         ' Scott ',            'Bad block #1 - Padding with whitespace');

eval { $sluz->parse_string('{first}') };
like($@, qr/73467/, 'Bad block #2 - {word}');

# -------------------------------------------------------------------
# Whitespace input/output
# -------------------------------------------------------------------
sluz_test($sluz, "{\$x}{\$x}"                                   , '77'                 , 'Whitespace input/output #1');
sluz_test($sluz, "{\$x} {\$x}"                                  , '7 7'                , 'Whitespace input/output #2');
sluz_test($sluz, "{\$x}\n{\$x}"                                 , "7\n7"               , 'Whitespace input/output #3');
sluz_test($sluz, "{foreach \$y as \$x}{\$x}{/foreach}"          , '246'                , 'Whitespace input/output #4');
sluz_test($sluz, "{foreach \$y as \$x}\n{\$x}\n{/foreach}"      , "2\n4\n6\n"          , 'Whitespace input/output #5');
sluz_test($sluz, "{if \$x}{\$x}{/if}"                           , '7'                  , 'Whitespace input/output #6');
sluz_test($sluz, "{if \$x}\n{\$x}\n{/if}"                       , "7\n"                , 'Whitespace input/output #7');
sluz_test($sluz, "{foreach \$y as \$x}\n{\$x}\n{/foreach}\nlast", "2\n4\n6\nlast"      , 'Whitespace input/output #8');
sluz_test($sluz, "{foreach \$array as \$x}{\$x} {/foreach}\nEND", "one two three \nEND", 'Whitespace input/output #9');

# -------------------------------------------------------------------
# Fetch tests
# -------------------------------------------------------------------
sluz_fetch_test($sluz, ['tpls/extra.stpl'],                qr/extra\.stpl/,            'Fetch #1 - Simple fetch');

{
    my $result = $sluz->fetch('tpls/child.stpl', 'tpls/parent.stpl');
    like($result, qr/Child TPL.*21c1a4c5/s, 'Parent/Child #1 - Fetch with two params');
}

$sluz->parent_tpl('tpls/parent.stpl');
{
    my $result = $sluz->fetch('tpls/child.stpl');
    like($result, qr/Child TPL.*21c1a4c5/s, 'Parent/Child #2 - Fetch with preset parent');
}
$sluz->parent_tpl(undef);
$sluz->{parent_tpl} = undef;

# -------------------------------------------------------------------
# Assign edge cases
# -------------------------------------------------------------------
eval { $sluz->assign('odd_args_test'); };
like($@, qr/#18956/, 'Assign #1 - Odd number of args (no-op)');

eval { $sluz->assign({}); };
is($@, "", 'Assign #2 - Empty hashref (no-op)');

# -------------------------------------------------------------------
# Variable edge cases
# -------------------------------------------------------------------
sluz_test($sluz, '{$hashref.nested.deep}',               'found',                     'Deep dive #1 - Three-level dotted hash access');
sluz_test($sluz, '{$bogus_var}',                         '',                          'Deep dive #2 - Undefined variable returns empty');
sluz_test($sluz, '{$null}',                              '',                          'Deep dive #3 - null variable returns empty');
sluz_test($sluz, '{$array}',                             'ARRAY',                     'Deep dive #4 - Array returned as scalar');

# -------------------------------------------------------------------
# Error edge cases
# -------------------------------------------------------------------
eval { $sluz->parse_string('{if}') };
like($@, qr/73467/, 'Error #5 - Bare {if} without condition');

done_testing();
