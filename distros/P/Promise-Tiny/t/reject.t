package t::reject;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;

use Promise::Tiny;

sub reject : Tests {
    Promise::Tiny->reject('oh my god')->then(sub {
        die;
    }, sub {
        my ($reason) = @_;
        is $reason, 'oh my god';
    });
}

__PACKAGE__->runtests;
