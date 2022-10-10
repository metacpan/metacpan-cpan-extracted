use strict;
use warnings;

use Tags::HTML::Pager::Utils qw(pages_num);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $ret = pages_num(4, 4);
is($ret, 1, '4 images and 4 images per page.');

# Test.
$ret = pages_num(4, 2);
is($ret, 2, '4 images and 2 images per page.');

# Test.
$ret = pages_num();
is($ret, 0, 'undef images and undef images per page.');

# Test.
$ret = pages_num(4);
is($ret, 0, '4 images and undef images per page.');

# Test.
$ret = pages_num(undef, 4);
is($ret, 0, 'undef images and 4 images per page.');
