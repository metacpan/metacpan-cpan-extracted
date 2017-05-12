use utf8;
use warnings FATAL => 'all';
use strict;

use Test::More tests => 2;

use Quote::Code;

is qc·a€b·, q·a€b·;
is qc‽$o‽, q‽$o‽;
