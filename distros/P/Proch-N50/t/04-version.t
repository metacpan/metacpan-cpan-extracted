use strict;
use warnings;
use Test::More;
eval 'use Test::GreaterVersion';
plan skip_all => 'Test::GreaterVersion required for this test' if $@;
has_greater_version_than_cpan('Proch::N50');
done_testing();
