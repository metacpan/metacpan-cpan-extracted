use strict;
use warnings;

use Tags::HTML::Message::Board::Blank;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Message::Board::Blank->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
