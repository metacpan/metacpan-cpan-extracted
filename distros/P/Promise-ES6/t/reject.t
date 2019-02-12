package t::reject;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;

use Promise::ES6;

sub reject : Tests {
    Promise::ES6->reject('oh my god')->then(sub {
        die;
    }, sub {
        my ($reason) = @_;
        is $reason, 'oh my god';
    });
}

__PACKAGE__->runtests;
