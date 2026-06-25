#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Foreach tests
# -------------------------------------------------------------------
sluz_test($sluz, '{foreach $array as $num}{$num}{/foreach}'                         , 'onetwothree'      , 'Foreach #1 - Simple');
sluz_test($sluz, "{foreach \$array as \$num}\n{\$num}\n{/foreach}"                  , "one\ntwo\nthree\n", 'Foreach #2 - Simple with whitespace');
sluz_test($sluz, '{foreach $members as $x}{$x.first}{/foreach}'                     , 'ScottJason'       , 'Foreach #3 - Hash');
sluz_test($sluz, '{foreach $arrayd as $x}{$x.1}{/foreach}'                          , '246'              , 'Foreach #4 - Array');
sluz_test($sluz, '{foreach $arrayd as $key => $val}{$key}:{$val.0}{/foreach}'       , '0:11:32:5'        , 'Foreach #6 - Key/val array');
sluz_test($sluz, '{foreach $members as $id => $x}{$id}{$x.first}{/foreach}'         , '0Scott1Jason'     , 'Foreach #7 - Key/val hash');
sluz_test($sluz, '{foreach $subarr.one as $id}{$id}{/foreach}'                      , '246'              , 'Foreach #8 - Hash key');
sluz_test($sluz, '{foreach $bogus_var as $x}one{/foreach}'                          , ''                 , 'Foreach #9 - Missing var');
sluz_test($sluz, '{foreach $empty as $x}one{/foreach}'                              , ''                 , 'Foreach #10 - Empty array');
sluz_test($sluz, '{foreach $array as $i => $x}{$i}{$x}{/foreach}'                   , '0one1two2three'   , 'Foreach #11 - One char variables');
sluz_test($sluz, '{foreach $array as $i => $x}{if $x}{$x}{/if}{/foreach}'           , 'onetwothree'      , 'Foreach #12 - Foreach with nested if');
sluz_test($sluz, '{foreach $arrayd as $i => $x}{if $x.1}{$x.1}{/if}{/foreach}'      , '246'              , 'Foreach #13 - Foreach with nested if (array)');
sluz_test($sluz, '{foreach $null as $x}one{/foreach}'                               , ''                 , 'Foreach #14 - Null');
sluz_test($sluz, '{foreach $first as $x}{$first}{/foreach}'                         , 'Scott'            , 'Foreach #15 - Scalar');
sluz_test($sluz, '{foreach $array as $i}{foreach $array as $i}x{/foreach}{/foreach}', 'xxxxxxxxx'        , 'Foreach #16 - Nested');

# Foreach variable persistence tests
sluz_test($sluz, '{$x}', '7', 'Foreach #17 - NOT overwrite variable - previously set');
sluz_test($sluz, '{$i}', '' , 'Foreach #18 - NOT overwrite variable - no initial value');

sluz_test($sluz, '{foreach $y as $z}{$z}{/foreach}'                                   , '246'                  , 'Foreach #19 - Foreach one char key');
sluz_test($sluz, '{foreach $array as $x}{if $__FOREACH_FIRST}FIRST{/if}{$x}{/foreach}', 'FIRSTonetwothree'     , 'Foreach #20 - Foreach FIRST item');
sluz_test($sluz, '{foreach $array as $x}{$x}{if $__FOREACH_LAST}LAST{/if}{/foreach}'  , 'onetwothreeLAST'      , 'Foreach #21 - Foreach LAST item');
sluz_test($sluz, '{foreach $array as $x}{$x}{$__FOREACH_INDEX}{/foreach}'             , 'one0two1three2'       , 'Foreach #22 - Foreach index');
sluz_test($sluz, '{foreach $colors as $k => $v}{$k}:{$v} {/foreach}'                  , 'a:red b:green c:blue ', 'Foreach #23 - Hashref iteration with key/val (sorted)');
sluz_test($sluz, '{foreach $scores as $val}{$val} {/foreach}'                         , '76 95 88 '            , 'Foreach #24 - Hashref iteration value only (sorted)');
sluz_test($sluz, '{foreach $empty as $k => $v}val{/foreach}'                          , ''                     , 'Foreach #25 - Empty array with key/val');
sluz_test($sluz, '{foreach $members as $i => $m}{$i}:{$m.first} {/foreach}'           , '0:Scott 1:Jason '     , 'Foreach #26 - Array of hashes with key/val');

done_testing();
