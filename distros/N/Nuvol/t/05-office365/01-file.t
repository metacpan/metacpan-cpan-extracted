use strict;

use Test::More;

use Nuvol::Test::File ':all';

my $package = 'Nuvol::Item';
my $service = 'Office365';

my $file = build_test_file $service;

test_basics $file, $service;

done_testing();
