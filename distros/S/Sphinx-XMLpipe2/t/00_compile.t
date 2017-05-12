use strict;
use Test::More 0.98 tests => 5;

use_ok $_ for qw(
    Sphinx::XMLpipe2
);

can_ok('Sphinx::XMLpipe2', 'new');
can_ok('Sphinx::XMLpipe2', 'fetch');
can_ok('Sphinx::XMLpipe2', 'add_data');
can_ok('Sphinx::XMLpipe2', 'remove_data');

done_testing;

