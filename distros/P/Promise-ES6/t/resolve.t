package t::resolve;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use parent qw(Test::Class);
use Test::More;
use Test::FailWarnings;

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
