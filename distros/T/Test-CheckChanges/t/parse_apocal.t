use strict;
use warnings;

require Test::CheckChanges;

Test::CheckChanges::ok_changes(
    base => 'examples/apocal'
);

