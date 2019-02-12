package t::resolve;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;

use Promise::ES6;

sub resolve : Tests {
    Promise::ES6->resolve(123)->then(sub {
        my ($value) = @_;
        is $value, 123;
    }, sub {
        die;
    });
}

__PACKAGE__->runtests;
