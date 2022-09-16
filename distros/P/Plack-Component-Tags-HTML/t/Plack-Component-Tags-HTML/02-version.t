use strict;
use warnings;

use Plack::Component::Tags::HTML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::Component::Tags::HTML::VERSION, 0.07, 'Version.');
