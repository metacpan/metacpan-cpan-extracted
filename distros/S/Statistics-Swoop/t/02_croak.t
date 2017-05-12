use strict;
use warnings;
use Test::More;

use Statistics::Swoop;

{
    eval {
        Statistics::Swoop->new;
    };

    like $@, qr/^first arg is required as array ref/, 'not array ref';
}

done_testing;
