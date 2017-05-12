use strict;
use Test::More tests => 1;

use PHP::Session;

eval {
    my $session = PHP::Session->new('---');
    fail 'no exception';
};
like $@, qr/Invalid/;
