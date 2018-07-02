use Test::Most;

use_ok('OpenOffice::OODoc::InsertDocument');

# check we injected OpenOffice::OODoc::Document with our methods
can_ok('OpenOffice::OODoc::Document' =>
    'insertDocument',
);

done_testing();
