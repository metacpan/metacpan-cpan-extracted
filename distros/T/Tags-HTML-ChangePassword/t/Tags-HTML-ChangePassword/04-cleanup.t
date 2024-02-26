use strict;
use warnings;

use Tags::HTML::ChangePassword;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::ChangePassword->new;
my $ret = $obj->cleanup;
is($ret, undef, 'Cleanup returns undef.');
