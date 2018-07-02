use Test::Most;

use_ok('OpenOffice::OODoc::HeadingStyles');

# check we injected OpenOffice::OODoc::Styles with our methods
can_ok('OpenOffice::OODoc::Styles' =>
    'createHeadingStyle',
    'establishHeadingStyle',
);

done_testing();
