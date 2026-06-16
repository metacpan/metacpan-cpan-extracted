#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/../lib';
use Template::Sluz;

use Test::More;

# -------------------------------------------------------------------
# Inject test helper functions into Template::Sluz namespace
# (so they're found by the modifier/expression eval machinery)
# -------------------------------------------------------------------
BEGIN {
    no strict 'refs';
    *{'main::truncate'}     = sub { substr($_[0], 0, $_[1]) };
    *{'main::join_comma'}   = sub { my $s = $_[1] // ', '; join $s, @{$_[0]} };
    *{'main::hello_world'}  = sub { "Hello world" };
    *{'main::return_false'} = sub { 0 };
    *{'main::return_null'}  = sub { undef };
}

# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------
my $sluz = Template::Sluz->new();
$sluz->assign('x'            => '7');
$sluz->assign('y'            => [2, 4, 6]);
$sluz->assign('key'          => 'val');
$sluz->assign('first'        => 'Scott');
$sluz->assign('last'         => 'Baker');
$sluz->assign('animal'       => 'Kitten');
$sluz->assign('word'         => 'cRaZy');
$sluz->assign('debug'        => 1);
$sluz->assign('array'        => ['one', 'two', 'three']);
$sluz->assign('cust'         => {first => 'Scott', last => 'Baker'});
$sluz->assign('number'       => 15);
$sluz->assign('zero'         => 0);
$sluz->assign('members'      => [{first => 'Scott', last => 'Baker'}, {first => 'Jason', last => 'Doolis'}]);
$sluz->assign('subarr'       => {one => [2, 4, 6], two => [3, 6, 9]});
$sluz->assign('arrayd'       => [[1, 2], [3, 4], [5, 6]]);
$sluz->assign('empty'        => []);
$sluz->assign('empty_string' => '');
$sluz->assign('null'         => undef);
$sluz->assign('true'         => 1);
$sluz->assign('false'        => 0);
$sluz->assign('conf'         => {main => 1, debug => 0});
$sluz->assign('colors', {a => 'red', b => 'green', c => 'blue'});
$sluz->assign('scores', {math => 95, science => 88, art => 76});
$sluz->assign('inc_file', 'tpls/extra.stpl');
$sluz->assign({color => 'yellow', age => 43, book => 'Dark Tower'});

# Assign a raw hash where all the keys live in the root namespace
my %data = (
	car     => 'Honda',
	ltuae   => 42,
	console => 'Nintendo',
	milk    => ['goat', 'cow', 'soy'],
);
$sluz->assign(%data);

$sluz->{perl_file_dir} = dirname(__FILE__);

# -------------------------------------------------------------------
# Test helpers
# -------------------------------------------------------------------
sub sluz_test {
    my ($input, $expected, $name) = @_;

    my $got;
    if (ref $input eq 'ARRAY') {
        my @blocks = $sluz->_get_blocks($input->[0]);
        $got = scalar @blocks;
    } else {
        $got = $sluz->parse_string($input);
    }

    my $is_regex;
    if ($expected =~ m|^/(.+)/$|) {
        $is_regex = 1;
    } else {
        $is_regex = 0;
    }

    if ($is_regex) {
        my $pat = $1;
        if ($got =~ /$pat/) {
            pass($name);
        } else {
            fail("$name -- expected pattern $expected, got " . explain($got));
        }
    } else {
        is($got, $expected, $name);
    }
}

sub sluz_fetch_test {
    my ($files, $pattern, $name) = @_;

    my $child  = $files->[0];
    my $parent = $files->[1];
    my $str = $sluz->fetch($child, $parent);

    if ($str =~ /$pattern/) {
        pass($name);
    } else {
        fail("$name -- expected $pattern, got " . explain($str));
    }
}

# -------------------------------------------------------------------
# Basic tests
# -------------------------------------------------------------------
sluz_test('Hello there',                             'Hello there',                 'Basic #1 - Static string');
sluz_test('{$first}',                                'Scott',                       'Basic #2 - Basic variable');
sluz_test('{$bogus_var}',                            '',                            'Basic #3 - Missing variable');
sluz_test('{$cust.first}',                           'Scott',                       'Basic #5 - Hash Lookup');
sluz_test('{$array.1}',                              'two',                         'Basic #6 - Array Lookup');
sluz_test('{$array|count}',                          '3',                           'Basic #7 - PHP Modifier array');
sluz_test('{$number + 3}',                           '18',                          'Basic #8 - Addition');
sluz_test('{$number * $debug}',                      '15',                          'Basic #9 - Multiplication of two vars');
sluz_test('{3}',                                     '3',                           'Basic #10 - Number literal');
sluz_test('{"Scott"}',                               'Scott',                       'Basic #11 - String literal');
sluz_test('{$x}',                                    '7',                           'Basic #12 - Single Character variable');
sluz_test('{$array[1]}',                             'two',                         'Basic #13 - Array Lookup - PHP Syntax');
sluz_test('{$cust["last"]}',                         'Baker',                       'Basic #14 - Hash Lookup - PHP Syntax');

# Default values
sluz_test('{$last|default:\'123\'}',                 'Baker',                       'Basic #15 - Default - Not Used');
sluz_test('{$zero|default:\'123\'}',                 '0',                           'Basic #16 - Default - Zero Not Used');
sluz_test('{$empty_string|default:\'123\'}',         '123',                         'Basic #17 - Default - Empty String');
sluz_test('{$null|default:\'123\'}',                 '123',                         'Basic #18 - Default - Null');
sluz_test('{$bogus_var|default:"?*%.|"}',            '?*%.|',                       'Basic #19 - Default - non word char');

# Undefined variables with modifiers
sluz_test('{$bogus_var|join}',                        '',                            'Basic #20 - Undefined var with array modifier');
sluz_test('{$bogus_var|uc}',                          '',                            'Basic #21 - Undefined var with string modifier');
sluz_test('{$bogus_var|count}',                       '',                            'Basic #22 - Undefined var with count modifier');
sluz_test('{$bogus_var|substr:0,2}',                  '',                            'Basic #23 - Undefined var with string modifier with params');

# Error tests (croak via eval)
eval { $sluz->parse_string('{foo') };
like($@, qr/45821/, 'Basic #24 - Unclosed block');

eval { $sluz->parse_string('{$first') };
like($@, qr/45821/, 'Basic #25 - Unclosed block variable');

# Hash with default
sluz_test('{$cust.first|default:\'Jason\'}',         'Scott',                       'Basic #26 - Hash with default value, not used');
sluz_test('{$cust.foo|default:\'Jason\'}',           'Jason',                       'Basic #27 - Hash with default value, used');
sluz_test('{$array}',                                'ARRAY',                       'Basic #28 - Array used as a scalar');
sluz_test('{$first|substr:2}',                       'ott',                         'Basic #29 - PHP function with one param');
sluz_test('{$first|substr:2,2}',                     'ot',                          'Basic #30 - PHP function with two params');

{
    local $TODO = "Negated hash lookup";
    sluz_test('{if !$cust.age}unknown{else}{$age}{/if}', 'unknown',                 'Basic #31 - Negated hash lookup');
}

sluz_test('{1.1234 + 2.3456}', '3.469'       , 'Basic #32 - Simple math that returns floating point');
sluz_test(''                 , ''            , 'Basic #33 - Empty template');
sluz_test(' '                , ' '           , 'Basic #34 - Whitespace only template');
sluz_test('{$bogus_var + 3}' , '3'           , 'Basic #35 - Undefined var in numeric expression');
sluz_test('{!$false}'        , '1'           , 'Basic #36 - Standalone negated expression (false to true)');
sluz_test('{!$true}'         , ''            , 'Basic #37 - Standalone negated expression (true to false)');
sluz_test('{$car}'           , 'Honda'       , 'Basic #38 - String variable set from hash');
sluz_test('{$ltuae}'         , '42'          , 'Basic #39 - Integer variable set from hash');
sluz_test('{$milk|join:":"}' , 'goat:cow:soy', 'Basic #40 - Array set from hash');

# -------------------------------------------------------------------
# Custom/User functions
# -------------------------------------------------------------------
sluz_test('{$word|truncate:3}',                      'cRa',                         'Custom function #1 - Modifier with param');
sluz_test('{$last|truncate:4|truncate:2}',           'Ba',                          'Custom function #2 - Two modifiers with params');
sluz_test('{$y|join_comma}',                         '2, 4, 6',                     'Custom function #3 - Function with default param');

{
    local $TODO = "join_comma with numeric param";
    sluz_test('{$y|join_comma:9}',                   '29496',                       'Custom function #4 - Function with integer param');
}

sluz_test('{$y|join_comma:"*"}',                     '2*4*6',                       'Custom function #5 - Function with string param');
sluz_test('{$y|join_comma:"|"}',                     '2|4|6',                       'Custom function #6 - Function with string param pipe');
sluz_test('{$y|join_comma:","}',                     '2,4,6',                       'Custom function #7 - Function with string param pipe comma');
sluz_test('{$y|join_comma:"\'"}',                    "2'4'6",                       'Custom function #8 - Function with string param pipe single quote');
sluz_test('{$y|join_comma:"; "}',                    "2; 4; 6",                     'Custom function #9 - Function with string param and space');
sluz_test("{\$y|join_comma:\"\t\"}",                 "2\t4\t6",                     'Custom function #10 - Function with string param and tab');

# Built-in join modifier
sluz_test('{$array|join}',                           'one, two, three',             'Built-in join #1 - default glue');
sluz_test('{$array|join:" - "}',                     'one - two - three',           'Built-in join #2 - custom glue');
sluz_test('{$array|join:","}',                       'one,two,three',               'Built-in join #3 - comma glue');

# -------------------------------------------------------------------
# Function blocks
# -------------------------------------------------------------------
sluz_test('{hello_world()}',                         'Hello world',                 'Function #1 - Hello world');

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
# If tests
# -------------------------------------------------------------------
sluz_test('{if $debug}DEBUG{/if}'                                                 , 'DEBUG'   , 'If #1 - Simple');
sluz_test('{if $bogus_var}DEBUG{/if}'                                             , ''        , 'If #2 - Missing var');
sluz_test('{if $debug}{$first}{/if}'                                              , 'Scott'   , 'If #3 - Variable as payload');
sluz_test('{if $debug}{if $debug}FOO{/if}{/if}'                                   , 'FOO'     , 'If #4 - Nested');
sluz_test('{if $x}{if $null}yes{else}no{/if}{/if}'                                , 'no'      , 'If #5 - Nested with else');
sluz_test('{if $one}{if $name}Yes{else}No{/if}{else}Unknown{/if}'                 , 'Unknown' , 'If #6 - Nested with two elses');
sluz_test('{if $bogus_var}YES{else}NO{/if}'                                       , 'NO'      , 'If #7 - Else');
sluz_test('{if $cust.first}{$cust.first}{/if}'                                    , 'Scott'   , 'If #8 - Hash lookup');
sluz_test('{if $number > 10}GREATER{/if}'                                         , 'GREATER' , 'If #9 - Comparison');
sluz_test('{if $bogus_var || $key}KEY{/if}'                                       , 'KEY'     , 'If #10 - ||');
sluz_test('{if $number == 15 && $debug}YES{/if}'                                  , 'YES'     , 'If #11 - Two comparisons');
sluz_test('{if !$verbose}QUIET{/if}'                                              , 'QUIET'   , 'If #12 - Negated comparison');
sluz_test('{if ($zero || $number > 10)}YES{/if}'                                  , 'YES'     , 'If #13 - Parens');
sluz_test('{if count($array) > 2}YES{/if}'                                        , 'YES'     , 'If #14 - PHP function conditional');
sluz_test('{if $debug}{$key}{$last}{/if}'                                         , 'valBaker', 'If #15 - Two block payload');
sluz_test('{if $debug}ONE{else}TWO{/if}'                                          , 'ONE'     , 'If #16 - Else not needed');
sluz_test('{if $zero}1{elseif $debug}2{else}3{/if}'                               , '2'       , 'If #17 - Elseif');
sluz_test('{if $key}{if $one}one{elseif $x}X{else}ELSE{/if}{/if}'                 , 'X'       , 'If #18 - Nested if with elseif');
sluz_test('{if $number}1{if $key}2{/if}3{/if}'                                    , '123'     , 'If #19 - Nested if leading/trailing chars');
sluz_test('{if $true}123{else}456{/if}'                                           , '123'     , 'If #20 - Boolean');
sluz_test('{if !$true}123{else}456{/if}'                                          , '456'     , 'If #21 - Boolean inverted');
sluz_test('{if $conf.main}123{else}456{/if}'                                      , '123'     , 'If #22 - Hash boolean');
sluz_test('{if !$conf.main}123{else}456{/if}'                                     , '456'     , 'If #23 - Hash boolean inverted');
sluz_test('{if $x}{if $y}yes{/if}{else}no{/if}'                                   , 'yes'     , 'If #24 - Nested if with an else');
sluz_test('{if true}a{else}b{if true}c{/if}{/if}'                                 , 'a'       , 'If #25 - Nested with true');
sluz_test('{if false}a{else}b{if true}c{/if}{/if}'                                , 'bc'      , 'If #26 - Nested with false');
sluz_test('{if true}{/if}'                                                        , ''        , 'If #27 - If with "" for payload');
sluz_test('{if $bogus_var}a{elseif $debug}b{elseif $true}c{else}d{/if}'           , 'b'       , 'If #28 - Multiple elseif (first match)');
sluz_test('{if $bogus_var}a{elseif $bogus_var2}b{elseif $true}c{else}d{/if}'      , 'c'       , 'If #29 - Multiple elseif (second match)');
sluz_test('{if $bogus_var}a{elseif $bogus_var2}b{elseif $bogus_var3}c{else}d{/if}', 'd'       , 'If #30 - Multiple elseif (all false, else)');

# -------------------------------------------------------------------
# Foreach tests
# -------------------------------------------------------------------
sluz_test('{foreach $array as $num}{$num}{/foreach}'                         , 'onetwothree'      , 'Foreach #1 - Simple');
sluz_test("{foreach \$array as \$num}\n{\$num}\n{/foreach}"                  , "one\ntwo\nthree\n", 'Foreach #2 - Simple with whitespace');
sluz_test('{foreach $members as $x}{$x.first}{/foreach}'                     , 'ScottJason'       , 'Foreach #3 - Hash');
sluz_test('{foreach $arrayd as $x}{$x.1}{/foreach}'                          , '246'              , 'Foreach #4 - Array');
sluz_test('{foreach $arrayd as $key => $val}{$key}:{$val.0}{/foreach}'       , '0:11:32:5'        , 'Foreach #6 - Key/val array');
sluz_test('{foreach $members as $id => $x}{$id}{$x.first}{/foreach}'         , '0Scott1Jason'     , 'Foreach #7 - Key/val hash');
sluz_test('{foreach $subarr.one as $id}{$id}{/foreach}'                      , '246'              , 'Foreach #8 - Hash key');
sluz_test('{foreach $bogus_var as $x}one{/foreach}'                          , ''                 , 'Foreach #9 - Missing var');
sluz_test('{foreach $empty as $x}one{/foreach}'                              , ''                 , 'Foreach #10 - Empty array');
sluz_test('{foreach $array as $i => $x}{$i}{$x}{/foreach}'                   , '0one1two2three'   , 'Foreach #11 - One char variables');
sluz_test('{foreach $array as $i => $x}{if $x}{$x}{/if}{/foreach}'           , 'onetwothree'      , 'Foreach #12 - Foreach with nested if');
sluz_test('{foreach $arrayd as $i => $x}{if $x.1}{$x.1}{/if}{/foreach}'      , '246'              , 'Foreach #13 - Foreach with nested if (array)');
sluz_test('{foreach $null as $x}one{/foreach}'                               , ''                 , 'Foreach #14 - Null');
sluz_test('{foreach $first as $x}{$first}{/foreach}'                         , 'Scott'            , 'Foreach #15 - Scalar');
sluz_test('{foreach $array as $i}{foreach $array as $i}x{/foreach}{/foreach}', 'xxxxxxxxx'        , 'Foreach #16 - Nested');

# Foreach variable persistence tests
sluz_test('{$x}', '7', 'Foreach #17 - NOT overwrite variable - previously set');
sluz_test('{$i}', '' , 'Foreach #18 - NOT overwrite variable - no initial value');

sluz_test('{foreach $y as $z}{$z}{/foreach}'                                   , '246'                  , 'Foreach #19 - Foreach one char key');
sluz_test('{foreach $array as $x}{if $__FOREACH_FIRST}FIRST{/if}{$x}{/foreach}', 'FIRSTonetwothree'     , 'Foreach #20 - Foreach FIRST item');
sluz_test('{foreach $array as $x}{$x}{if $__FOREACH_LAST}LAST{/if}{/foreach}'  , 'onetwothreeLAST'      , 'Foreach #21 - Foreach LAST item');
sluz_test('{foreach $array as $x}{$x}{$__FOREACH_INDEX}{/foreach}'             , 'one0two1three2'       , 'Foreach #22 - Foreach index');
sluz_test('{foreach $colors as $k => $v}{$k}:{$v} {/foreach}'                  , 'a:red b:green c:blue ', 'Foreach #23 - Hashref iteration with key/val (sorted)');
sluz_test('{foreach $scores as $val}{$val} {/foreach}'                         , '76 95 88 '            , 'Foreach #24 - Hashref iteration value only (sorted)');
sluz_test('{foreach $empty as $k => $v}val{/foreach}'                          , ''                     , 'Foreach #25 - Empty array with key/val');
sluz_test('{foreach $members as $i => $m}{$i}:{$m.first} {/foreach}'           , '0:Scott 1:Jason '     , 'Foreach #26 - Array of hashes with key/val');

# -------------------------------------------------------------------
# Plain text tests
# -------------------------------------------------------------------
sluz_test('Scott',              'Scott',              'Plain text #1 - Static text');
sluz_test('<div>Scott</div>',   '<div>Scott</div>',   'Plain text #2 - HTML');

# -------------------------------------------------------------------
# Bad block tests
# -------------------------------------------------------------------
sluz_test(' {$first} ',         ' Scott ',            'Bad block #1 - Padding with whitespace');

eval { $sluz->parse_string('{first}') };
like($@, qr/73467/, 'Bad block #2 - {word}');

# -------------------------------------------------------------------
# Literal tests
# -------------------------------------------------------------------
sluz_test('{literal}{{/literal}'                  , '{'                  , 'Literal #1 - {');
sluz_test('{literal}}{/literal}'                  , '}'                  , 'Literal #2 - }');
sluz_test('{literal}{}{/literal}'                 , '{}'                 , 'Literal #3 - Literal + {}');
sluz_test('{literal}{foreach}{/literal}'          , '{foreach}'          , 'Literal #4 - {literal}');
sluz_test('{literal}{literal}{/literal}{/literal}', '{literal}{/literal}', 'Literal #5 - Meta literal');
sluz_test(' { '                                   , ' { '                , 'Literal #6 - { with whitespace');
sluz_test('{}'                                    , '{}'                 , 'Literal #7 - Raw {}');

# -------------------------------------------------------------------
# Whitespace input/output
# -------------------------------------------------------------------
sluz_test("{\$x}{\$x}"                                   , '77'                 , 'Whitespace input/output #1');
sluz_test("{\$x} {\$x}"                                  , '7 7'                , 'Whitespace input/output #2');
sluz_test("{\$x}\n{\$x}"                                 , "7\n7"               , 'Whitespace input/output #3');
sluz_test("{foreach \$y as \$x}{\$x}{/foreach}"          , '246'                , 'Whitespace input/output #4');
sluz_test("{foreach \$y as \$x}\n{\$x}\n{/foreach}"      , "2\n4\n6\n"          , 'Whitespace input/output #5');
sluz_test("{if \$x}{\$x}{/if}"                           , '7'                  , 'Whitespace input/output #6');
sluz_test("{if \$x}\n{\$x}\n{/if}"                       , "7\n"                , 'Whitespace input/output #7');
sluz_test("{foreach \$y as \$x}\n{\$x}\n{/foreach}\nlast", "2\n4\n6\nlast"      , 'Whitespace input/output #8');
sluz_test("{foreach \$array as \$x}{\$x} {/foreach}\nEND", "one two three \nEND", 'Whitespace input/output #9');

# -------------------------------------------------------------------
# Comment tests
# -------------------------------------------------------------------
sluz_test('{* Comment *}'                       , '', 'Comment #1 - With text');
sluz_test('{* ********* *}'                     , '', 'Comment #2 - ******');
sluz_test('{**}'                                , '', 'Comment #3 - No whitespace');
sluz_test('{*{$array|count}*}'                  , '', 'Comment #4 - Variable inside');
sluz_test('{* {* nested *} *}'                  , '', 'Comment #5 - Nested');
sluz_test('{* {* {* nested *} *} *}'            , '', 'Comment #6 - Triple Nested');
sluz_test('{* {* {* {* nested *} *} *} *}'      , '', 'Comment #7 - 4-level nested');
sluz_test('{* {* {* {* {* nested *} *} *} *} *}', '', 'Comment #8 - 5-level nested (max depth)');

# -------------------------------------------------------------------
# Include tests
# -------------------------------------------------------------------
sluz_test("{include file='tpls/extra.stpl'}", '/e1ab49cf/', 'Include #1 - file=extra.stpl');
sluz_test("{include 'tpls/extra.stpl'}"     , '/e1ab49cf/', "Include #2 - 'extra.stpl'");

eval { $sluz->parse_string('{include}') };
like($@, qr/73467/, 'Include #3 - No payload');

sluz_test("{include file='tpls/extra.stpl' secret='eca4906'}", '/eca4906/' , 'Include #4 - With variable');
sluz_test("{include file=\"\$inc_file\"}"                    , '/e1ab49cf/', 'Include #5 - With variable file path');
sluz_test("{include file='tpls/nested_inc.stpl'}"            , '/e1ab49cf/', 'Include #6 - Nested include');
sluz_test("{include file='tpls/var_scope.stpl'}"             , '/SCOPE:15/', 'Include #7 - Variable scope (parent vars visible)');

# -------------------------------------------------------------------
# Get blocks tests
# -------------------------------------------------------------------

{
	my @x = $sluz->_get_blocks('{$a}{$b}{$c}');
	is(scalar @x, 3, 'Get blocks #1 - Basic variables');
}

{
	my @x = $sluz->_get_blocks('{if $a}{$a}{/if}');
	is(scalar @x, 1, 'Get blocks #2 - Basic variables');
}

{
	my @x = $sluz->_get_blocks('Jason{$a}Baker{$b}');
	is(scalar @x, 4, 'Get blocks #3 - Basic variables');
}

{
	my @x = $sluz->_get_blocks('function(foo) { $i = 10; }');
	is(scalar @x, 1, 'Get blocks #4 - javascript function');
}

{
	my @x = $sluz->_get_blocks('{* Comment *}ABC{* Comment *}');
	is(scalar @x, 1, 'Get blocks #5 - Comments');
}

{
	my @x = $sluz->_get_blocks('   {$x}   ');
	is(scalar @x, 3, 'Get blocks #6 - Whitespace around variable');
}

{
	my @x = $sluz->_get_blocks('{foreach $arr as $i => $x}{if $x.1}{$x.1}{/if}{/foreach}');
	is(scalar @x, 1, 'Get blocks #7 - Lots of brackets');
}

{
	my @x = $sluz->_get_blocks('{*{$first}*}');
	is(scalar @x, 0, 'Get blocks #8 - Comment with variable');
}

{
	my @x = $sluz->_get_blocks('{*{$first} {$last}*}');
	is(scalar @x, 0, 'Get blocks #9 - Comments with variables');
}

{
	my @x = $sluz->_get_blocks(' {* {$foo} *} ');
	is(scalar @x, 2, 'Get blocks #10 - Comments with variables and whitespace');
}

{
	my @x = $sluz->_get_blocks('{foreach $array as $i}{foreach $array as $i}x{/foreach}{/foreach}');
	is(scalar @x, 1, 'Get blocks #11 - Nested foreach');
}

{
	my @x = $sluz->_get_blocks("{\$foo}\n{\$bar}");
	is(scalar @x, 3, 'Get blocks #12 - Only whitespace block');
}

{
	my @x = $sluz->_get_blocks("{\$foo}\n\n{\$bar}");
	is(scalar @x, 3, 'Get blocks #13 - Double whitespace block');
}

{
	my @x = $sluz->_get_blocks('');
	is(scalar @x, 0, 'Get blocks #14 - Empty string');
}

{
	my @x = $sluz->_get_blocks('plain text only');
	is(scalar @x, 1, 'Get blocks #15 - No template tags');
}

{
	my @x = $sluz->_get_blocks('{* {* {* {* deep *} *} *} *}');
	is(scalar @x, 0, 'Get blocks #16 - Deeply nested comment (4 levels)');
}
# -------------------------------------------------------------------
# Fetch tests
# -------------------------------------------------------------------
sluz_fetch_test(['tpls/extra.stpl'],                qr/extra\.stpl/,            'Fetch #1 - Simple fetch');

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
$sluz->assign('hashref', {nested => {deep => 'found'}});
sluz_test('{$hashref.nested.deep}',               'found',                     'Deep dive #1 - Three-level dotted hash access');
sluz_test('{$bogus_var}',                         '',                          'Deep dive #2 - Undefined variable returns empty');
sluz_test('{$null}',                              '',                          'Deep dive #3 - null variable returns empty');
sluz_test('{$array}',                             'ARRAY',                     'Deep dive #4 - Array returned as scalar');

# -------------------------------------------------------------------
# Error edge cases
# -------------------------------------------------------------------
eval { $sluz->parse_string('{if}') };
like($@, qr/73467/, 'Error #5 - Bare {if} without condition');

done_testing();
