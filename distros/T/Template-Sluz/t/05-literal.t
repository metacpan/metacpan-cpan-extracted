#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Literal tests
# -------------------------------------------------------------------
sluz_test($sluz, '{literal}{{/literal}'                  , '{'                  , 'Literal #1 - {');
sluz_test($sluz, '{literal}}{/literal}'                  , '}'                  , 'Literal #2 - }');
sluz_test($sluz, '{literal}{}{/literal}'                 , '{}'                 , 'Literal #3 - Literal + {}');
sluz_test($sluz, '{literal}{foreach}{/literal}'          , '{foreach}'          , 'Literal #4 - {literal}');
sluz_test($sluz, '{literal}{literal}{/literal}{/literal}', '{literal}{/literal}', 'Literal #5 - Meta literal');
sluz_test($sluz, ' { '                                   , ' { '                , 'Literal #6 - { with whitespace');
sluz_test($sluz, '{}'                                    , '{}'                 , 'Literal #7 - Raw {}');

done_testing();
