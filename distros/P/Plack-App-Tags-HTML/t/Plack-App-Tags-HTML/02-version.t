use strict;
use warnings;

use Plack::App::Tags::HTML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Tags::HTML::VERSION, 0.17, 'Version.');
