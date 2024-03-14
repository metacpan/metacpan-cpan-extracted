use strict;
use warnings;

use Plack::App::CPAN::Changes;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Plack::App::CPAN::Changes::VERSION, 0.01, 'Version.');
