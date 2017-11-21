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
    use Moxie
        traits => [':experimental'];

    use Scalar::Util ();

    extends 'Moxie::Object';

    has node  => ();
    has left  => ();
    has right => ();

    has _parent => ();

    my sub _parent : private;

    sub BUILDARGS : strict(
        node?   => _node,
        parent? => _parent,
    );

    sub BUILD ($self, $) { Scalar::Util::weaken( _parent ) }

    sub node   : rw;
    sub parent : ro(_parent);

    sub has_parent : predicate(_parent);
    sub has_left   : predicate;
    sub has_right  : predicate;

    sub left  ($self) : lazy { $self->new( parent => $self ) }
    sub right ($self) : lazy { $self->new( parent => $self ) }
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

    ok(Scalar::Util::isweak( $t->left->{_parent} ), '... the field was weakened correctly');

    ok($t->right->has_parent, '... right has a parent');
    is($t->right->parent, $t, '... and it is us');

    ok(Scalar::Util::isweak( $t->right->{_parent} ), '... the field was weakened correctly');
}

{
    my $left  = BinaryTree->new;
    like(
        exception { BinaryTree->new( left => $left ) },
        qr/^Constructor for \(BinaryTree\) got unrecognized parameters \(`left`\)/,
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

    ok(Scalar::Util::isweak( $t->left->{_parent} ), '... the field was weakened correctly');
    ok(Scalar::Util::isweak( $t->right->{_parent} ), '... the field was weakened correctly');
}

done_testing;
