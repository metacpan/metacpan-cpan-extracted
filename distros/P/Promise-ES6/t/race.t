package t::race;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use PromiseTest;

use parent qw(Test::Class);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;

use Promise::ES6;

sub race_with_value : Tests {
    my ($self) = @_;

    my $resolve_cr;

    # This will never resolve.
    my $p1 = Promise::ES6->new(sub {});

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });

    my $value = PromiseTest::await( Promise::ES6->race([$p1, $p2]) );

    is $value, 2, 'got raw value instantly';
}

__PACKAGE__->new()->runtests;
