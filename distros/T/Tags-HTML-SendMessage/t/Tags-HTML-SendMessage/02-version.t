use strict;
use warnings;

use Tags::HTML::SendMessage;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::HTML::SendMessage::VERSION, 0.09, 'Version.');
