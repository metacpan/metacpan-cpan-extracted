use strict;

use Test::More;
use Nuvol::Test::ItemLive ':all';
use Mojo::File 'path';

my $service = 'Dropbox';

my $item = build_test_item $service, '/Public';

test_basics $item, $service;

done_testing();
