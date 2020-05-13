use strict;
use warnings;
use Cwd;

use Test::More;
use Test::Requires 'Test::Strict';

$Test::Strict::TEST_SYNTAX = 1;
$Test::Strict::TEST_STRICT = 1;
$Test::Strict::TEST_WARNINGS = 1;
$Test::Strict::TEST_SKIP = [ glob(getcwd()."/t/../.git/hooks/*") ];

all_perl_files_ok();
