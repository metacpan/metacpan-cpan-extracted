use Test::More;
use strict;
use warnings;
use lib qw(t/lib);

use_ok 'Album',
  'No trouble loading the Album class';

ok my $album = Album->new(
    storage_args=>[source=>'./t/share'],
    storage_class=>'Album::Storage::File',
), 'Created a new album';

is $album->title, 'My Album',
  'Got expected title';

ok $album->resource_types,
  'No errors trying to get the resource_types';

ok $album->storage,
  'No errors trying to get the storage';

ok $album->set,
  'No errors trying to get the set';

is $album->set->randomize->slice(0,3)->all, 3,
  'got expected number of items (3)';

done_testing();
