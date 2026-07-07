#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# If tests
# -------------------------------------------------------------------
sluz_test($sluz, '{if $debug}DEBUG{/if}'                                                 , 'DEBUG'   , 'If #1 - Simple');
sluz_test($sluz, '{if $bogus_var}DEBUG{/if}'                                             , ''        , 'If #2 - Missing var');
sluz_test($sluz, '{if $debug}{$first}{/if}'                                              , 'Scott'   , 'If #3 - Variable as payload');
sluz_test($sluz, '{if $debug}{if $debug}FOO{/if}{/if}'                                   , 'FOO'     , 'If #4 - Nested');
sluz_test($sluz, '{if $x}{if $null}yes{else}no{/if}{/if}'                                , 'no'      , 'If #5 - Nested with else');
sluz_test($sluz, '{if $one}{if $name}Yes{else}No{/if}{else}Unknown{/if}'                 , 'Unknown' , 'If #6 - Nested with two elses');
sluz_test($sluz, '{if $bogus_var}YES{else}NO{/if}'                                       , 'NO'      , 'If #7 - Else');
sluz_test($sluz, '{if $cust.first}{$cust.first}{/if}'                                    , 'Scott'   , 'If #8 - Hash lookup');
sluz_test($sluz, '{if $number > 10}GREATER{/if}'                                         , 'GREATER' , 'If #9 - Comparison');
sluz_test($sluz, '{if $bogus_var || $key}KEY{/if}'                                       , 'KEY'     , 'If #10 - ||');
sluz_test($sluz, '{if $number == 15 && $debug}YES{/if}'                                  , 'YES'     , 'If #11 - Two comparisons');
sluz_test($sluz, '{if !$verbose}QUIET{/if}'                                              , 'QUIET'   , 'If #12 - Negated comparison');
sluz_test($sluz, '{if ($zero || $number > 10)}YES{/if}'                                  , 'YES'     , 'If #13 - Parens');
sluz_test($sluz, '{if count($array) > 2}YES{/if}'                                        , 'YES'     , 'If #14 - PHP function conditional');
sluz_test($sluz, '{if $debug}{$key}{$last}{/if}'                                         , 'valBaker', 'If #15 - Two block payload');
sluz_test($sluz, '{if $debug}ONE{else}TWO{/if}'                                          , 'ONE'     , 'If #16 - Else not needed');
sluz_test($sluz, '{if $zero}1{elseif $debug}2{else}3{/if}'                               , '2'       , 'If #17 - Elseif');
sluz_test($sluz, '{if $key}{if $one}one{elseif $x}X{else}ELSE{/if}{/if}'                 , 'X'       , 'If #18 - Nested if with elseif');
sluz_test($sluz, '{if $number}1{if $key}2{/if}3{/if}'                                    , '123'     , 'If #19 - Nested if leading/trailing chars');
sluz_test($sluz, '{if $true}123{else}456{/if}'                                           , '123'     , 'If #20 - Boolean');
sluz_test($sluz, '{if !$true}123{else}456{/if}'                                          , '456'     , 'If #21 - Boolean inverted');
sluz_test($sluz, '{if $conf.main}123{else}456{/if}'                                      , '123'     , 'If #22 - Hash boolean');
sluz_test($sluz, '{if !$conf.main}123{else}456{/if}'                                     , '456'     , 'If #23 - Hash boolean inverted');
sluz_test($sluz, '{if $x}{if $y}yes{/if}{else}no{/if}'                                   , 'yes'     , 'If #24 - Nested if with an else');
sluz_test($sluz, '{if true}a{else}b{if true}c{/if}{/if}'                                 , 'a'       , 'If #25 - Nested with true');
sluz_test($sluz, '{if false}a{else}b{if true}c{/if}{/if}'                                , 'bc'      , 'If #26 - Nested with false');
sluz_test($sluz, '{if true}{/if}'                                                        , ''        , 'If #27 - If with "" for payload');
sluz_test($sluz, '{if $bogus_var}a{elseif $debug}b{elseif $true}c{else}d{/if}'           , 'b'       , 'If #28 - Multiple elseif (first match)');
sluz_test($sluz, '{if $bogus_var}a{elseif $bogus_var2}b{elseif $true}c{else}d{/if}'      , 'c'       , 'If #29 - Multiple elseif (second match)');
sluz_test($sluz, '{if $bogus_var}a{elseif $bogus_var2}b{elseif $bogus_var3}c{else}d{/if}', 'd'       , 'If #30 - Multiple elseif (all false, else)');

# Whitespace parity: leading newline stripped from if/else/elseif payloads
sluz_test($sluz, "{if \$x}\nYES\n{/if}"                                                   , "YES\n"  , 'If #31 - Leading newline stripped from true branch');
sluz_test($sluz, "{if \$zero}\nYES\n{else}\nNO\n{/if}"                                    , "NO\n"   , 'If #32 - Leading newline stripped from else branch');
sluz_test($sluz, "{if \$zero}\n1\n{elseif \$debug}\n2\n{else}\n3\n{/if}"                   , "2\n"    , 'If #33 - Leading newline stripped from elseif branch');
sluz_test($sluz, "{if \$bogus_var}\n1\n{elseif \$bogus_var2}\n2\n{elseif \$debug}\n3\n{else}\n4\n{/if}", "3\n", 'If #34 - Leading newline stripped from latter elseif branch');

done_testing();
