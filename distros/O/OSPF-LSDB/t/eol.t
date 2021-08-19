use strict;
use warnings;

use Test::More;
use Test::Requires 'Test::EOL';

all_perl_files_ok({ trailing_whitespace => 1 });
