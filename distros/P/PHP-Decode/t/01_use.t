# Tests: use

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More tests => 7;

use_ok('PHP::Decode');
use_ok('PHP::Decode::Tokenizer');
use_ok('PHP::Decode::Parser');
use_ok('PHP::Decode::Array');
use_ok('PHP::Decode::Op');
use_ok('PHP::Decode::Transformer');
use_ok('PHP::Decode::Func');


