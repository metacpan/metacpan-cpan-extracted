package t::resolve;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;

use Promise::Tiny;

sub resolve : Tests {
    Promise::Tiny->resolve(123)->then(sub {
        my ($value) = @_;
        is $value, 123;
    }, sub {
        die;
    });
}

__PACKAGE__->runtests;
