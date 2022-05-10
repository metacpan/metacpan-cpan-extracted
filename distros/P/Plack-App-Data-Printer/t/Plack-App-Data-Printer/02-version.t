use strict;
use warnings;

use Plack::App::Data::Printer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::Data::Printer::VERSION, 0.04, 'Version.');
