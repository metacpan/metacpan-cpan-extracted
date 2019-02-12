package t::then_catch;

use strict;
use warnings;

use Test::More;
use parent qw(Test::Class);

use Promise::ES6;

sub then_catch : Tests {
    my $caught;

    my $p = Promise::ES6->new( sub {
        my ($y, $n) = @_;

        $n->('oops');
    } );

    my $p2 = $p->then( sub { does_not_matter() } );

    $p2->catch( sub {
        $caught = $_[0];
    } );

    is( $caught, 'oops', 'caught as expected' );
}

__PACKAGE__->runtests() if !caller;
