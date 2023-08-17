use strict;
use warnings;

use Plack::App::Search;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Search::VERSION, 0.02, 'Version.');
