#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;
use Scalar::Util;

BEGIN {
    use_ok('MOP');
}

=pod

TODO:

=cut


package BinaryTree {
    use Moxie;

    use Scalar::Util ();

    extends 'Moxie::Object';

    has 'node';
    has 'parent';
    has 'left';
    has 'right';

    my sub _parent : private('parent');
    my sub _left   : private('left');
    my sub _right  : private('right');

    sub BUILDARGS : init_args( left => undef, right => undef );

    sub BUILD ($self, $) { Scalar::Util::weaken( _parent ) }

    sub node   : rw;
    sub parent : ro;

    sub has_parent : predicate;
    sub has_left   : predicate;
    sub has_right  : predicate;

    sub left  ($self) { _left  //= $self->new( parent => $self ) }
    sub right ($self) { _right //= $self->new( parent => $self ) }
}

{
    my $t = BinaryTree->new;
    ok($t->isa('BinaryTree'), '... this is a BinaryTree object');

    ok(!$t->has_parent, '... this tree has no parent');

    ok(!$t->has_left, '... left node has not been created yet');
    ok(!$t->has_right, '... right node has not been created yet');

    ok($t->left->isa('BinaryTree'), '... left is a BinaryTree object');
    ok($t->right->isa('BinaryTree'), '... right is a BinaryTree object');

    ok($t->has_left, '... left node has now been created');
    ok($t->has_right, '... right node has now been created');

    ok($t->left->has_parent, '... left has a parent');
    is($t->left->parent, $t, '... and it is us');

    ok(Scalar::Util::isweak( $t->left->{parent} ), '... the field was weakened correctly');

    ok($t->right->has_parent, '... right has a parent');
    is($t->right->parent, $t, '... and it is us');

    ok(Scalar::Util::isweak( $t->right->{parent} ), '... the field was weakened correctly');
}

{
    # this tests the `init_arg => undef` thing
    my $left  = BinaryTree->new;
    like(
        exception { BinaryTree->new( left => $left ) },
        qr/^Attempt to set slot\[left\] in constructor\, but slot has been declared un-settable \(init_arg \= undef\)/,
        '... got the exception we expected'
    );

}

package MyBinaryTree {
    use Moxie;

    extends 'BinaryTree';
}

{
    my $t = MyBinaryTree->new;
    ok($t->isa('MyBinaryTree'), '... this is a MyBinaryTree object');
    ok($t->isa('BinaryTree'), '... this is a BinaryTree object');

    ok(!$t->has_parent, '... this tree has no parent');

    ok(!$t->has_left, '... left node has not been created yet');
    ok(!$t->has_right, '... right node has not been created yet');

    ok($t->left->isa('BinaryTree'), '... left is a BinaryTree object');
    ok($t->right->isa('BinaryTree'), '... right is a BinaryTree object');

    ok($t->has_left, '... left node has now been created');
    ok($t->has_right, '... right node has now been created');

    ok(Scalar::Util::isweak( $t->left->{parent} ), '... the field was weakened correctly');
    ok(Scalar::Util::isweak( $t->right->{parent} ), '... the field was weakened correctly');
}

done_testing;
