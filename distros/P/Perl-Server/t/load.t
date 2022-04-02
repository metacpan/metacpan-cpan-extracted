use Test::More;

use_ok('Perl::Server');

can_ok(
    'Perl::Server',
    'new',
    'run'
);

done_testing;
