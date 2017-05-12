# Pragmas.
use strict;
use warnings;

# Modules.
use Task::WWW::Search::Antiquarian::Czech;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::WWW::Search::Antiquarian::Czech::VERSION, 0.01, 'Version.');
