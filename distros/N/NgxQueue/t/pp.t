use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    $ENV{PERL_ONLY} = 1;
}
use NgxQueue;

is NgxQueue::BACKEND, 'PP';
new_ok 'NgxQueue';

done_testing;
