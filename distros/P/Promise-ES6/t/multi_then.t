package t::multi_then;

use strict;
use warnings;

use Test::More;
use parent qw(Test::Class);

use Promise::ES6;

sub multi_then : Tests {
    my $caught;

    my ($resolve, $reject);

    my $p = Promise::ES6->new( sub {
        ($resolve, $reject) = @_;
    } );

    my $then1_ok;
    my $then1 = $p->then( sub { $then1_ok = 1 } );

    my $then2_ok;
    my $then2 = $p->then( sub { $then2_ok = 1 } );

    $resolve->(123);

    ok( $then1_ok, 'first then() called' );
    ok( $then2_ok, 'second then() called' );
}

__PACKAGE__->runtests() if !caller;
