# Pragmas.
use strict;
use warnings;

# Modules.
use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Task::WWW::Search::Antiquarian::Czech', 'Task::WWW::Search::Antiquarian::Czech is covered.');
