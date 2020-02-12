use strict;

use Test::More;
use Nuvol::Test::ItemLive ':all';
use Mojo::File 'path';

my $service = 'Office365';

my $item = build_test_item $service;

test_basics $item, $service;

done_testing();
