# Test the checks for invalid usage.

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Sort::Bucket qw(inplace_bucket_sort);

my @a;


dies_ok { inplace_bucket_sort @a, -1 } "reject -ve bits";
dies_ok { inplace_bucket_sort @a, 32 } "reject overlarge bits";
lives_ok { inplace_bucket_sort @a } "accept bucket bits omitted";

foreach my $bits (0 .. 20) {
    lives_ok { inplace_bucket_sort @a, $bits } "accept $bits bucket bits";
}

Sort::Bucket::_set_readonly_for_testing @a;
dies_ok { inplace_bucket_sort @a } "reject readonly array";

done_testing;

