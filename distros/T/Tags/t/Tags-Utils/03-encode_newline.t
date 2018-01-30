use strict;
use warnings;

use Tags::Utils qw(encode_newline);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $string = "text\ntext";
my $ret = encode_newline($string);
is($ret, 'text\\ntext');
