#!perl

use strict;
use warnings;

use Test::More;

use_ok 'Parse::Template';

is Parse::Template->DEBUG, 0, "DEBUG is off";
is Parse::Template->TRACE_ENV, 0, "TRACE_ENV is off";
is Parse::Template->EVAL_TRACE, 0, "EVAL_TRACE is off";
is Parse::Template->SHOW_PART, 0, "SHOW_PART is off";
is Parse::Template->SIGN_PART, 0, "SIGN_PART is off";

done_testing();
