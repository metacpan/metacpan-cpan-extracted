use strict;
use warnings;

use Tags::HTML::Table::View;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Table::View->new;
isa_ok($obj, 'Tags::HTML::Table::View');
