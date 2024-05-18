use strict;
use warnings;

use Tags::HTML::DefinitionList;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::DefinitionList::VERSION, 0.02, 'Version.');
