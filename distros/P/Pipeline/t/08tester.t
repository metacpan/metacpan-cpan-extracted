use lib './lib';

use strict;
use warnings;

use Test::More tests => 5;

use Pipeline::Segment::Tester;

my $pt   = Pipeline::Segment::Tester->new();
my $seg  = Test::Segment->new();
my $obj  = bless( { test => 1 }, 'Test' );
my $prod = $pt->test( $seg, $obj );

is( $pt->pipe->store->get('Test'), $obj, 'obj still in store' );

my $pt2  = Pipeline::Segment::Tester->new();
is( $pt2->pipe->store->get('Test'), undef, 'store reset' );


package Test::Segment;

use Test::More;

use base qw( Pipeline::Segment );

sub dispatch {
    my $self = shift;
    my $pipe = shift;

    ok( $pipe, 'dispatch( $pipe )' );

    ok( $self->parent, '$self->parent set on dispatch' );
    ok( $self->store,  '$self->store set on dispatch' );

    return;
}

