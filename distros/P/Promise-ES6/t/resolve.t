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

sub resolve : Tests(1) {
    Promise::ES6->resolve(123)->then(sub {
        my ($value) = @_;
        is $value, 123;
    }, sub {
        die;
    });
}

sub resolve_with_promise : Tests(1) {
    note "NONSTANDARD: The Promises/A+ test suite purposely avoids flexing this, but we match ES6.";

    my ($y, $n);

    my $p = Promise::ES6->new( sub {
        ($y, $n) = @_;
    } );

    $y->( Promise::ES6->resolve(123) );

    $p->then( sub {
        my $v = shift;

        is($v, 123, 'resolve with promise propagates');
    } );
}

__PACKAGE__->runtests;
