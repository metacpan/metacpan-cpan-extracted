#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

package LinkedList {
    use Moxie;

    extends 'Moxie::Object';

    has '_head';
    has '_tail';
    has '_count' => ( default => sub { 0 } );

    my sub _head  : private;
    my sub _tail  : private;
    my sub _count : private;

    # public read only accessors

    sub head  : ro( _head );
    sub tail  : ro( _tail );
    sub count : ro( _count );

    # methods

    sub append ($self, $node) {
        unless ( _tail ) {
            _tail = $node;
            _head = $node;
            _count++;
            return;
        }
        _tail->set_next($node);
        $node->set_previous(_tail);
        _tail = $node;
        _count++;
    }

    sub insert ($self, $index, $node) {
        die "Index ($index) out of bounds"
            if $index < 0 or $index > _count - 1;

        my $tmp = _head;
        $tmp = $tmp->get_next while($index--);
        $node->set_previous($tmp->get_previous);
        $node->set_next($tmp);
        $tmp->get_previous->set_next($node);
        $tmp->set_previous($node);
        _count++;
    }

    sub remove ($self, $index) {
        die "Index ($index) out of bounds"
            if $index < 0 or $index > _count - 1;

        my $tmp = _head;
        $tmp = $tmp->get_next while($index--);
        $tmp->get_previous->set_next($tmp->get_next);
        $tmp->get_next->set_previous($tmp->get_previous);
        _count--;
        $tmp->detach();
    }

    sub prepend ($self, $node) {
        unless ( _head ) {
            _tail = $node;
            _head = $node;
            _count++;
            return;
        }
        _head->set_previous($node);
        $node->set_next(_head);
        _head = $node;
        _count++;
    }

    sub sum ($self) {
        my $sum = 0;
        my $tmp = _head;
        do { $sum += $tmp->get_value } while($tmp = $tmp->get_next);
        return $sum;
    }
}

package LinkedListNode {
    use Moxie;

    extends 'Moxie::Object';

    # private slots

    has '_prev';
    has '_next';

    my sub _prev : private;
    my sub _next : private;

    # public slot

    has 'value';

    # public r/w API

    sub get_previous : ro( _prev );
    sub get_next     : ro( _next );
    sub get_value    : ro;

    sub set_previous : wo( _prev );
    sub set_next     : wo( _next );
    sub set_value    : wo;

    sub detach {
        _prev = undef;
        _next = undef;
        $_[0]
    }
}

{
    my $ll = LinkedList->new();

    for (0..9) {
        $ll->append(
            LinkedListNode->new('value' => $_)
        );
    }

    is($ll->head->get_value, 0, '... head is 0');
    is($ll->tail->get_value, 9, '... tail is 9');
    is($ll->count, 10, '... count is 10');

    $ll->prepend(LinkedListNode->new('value' => -1));
    is($ll->count, 11, '... count is now 11');

    $ll->insert(5, LinkedListNode->new('value' => 11));
    is($ll->count, 12, '... count is now 12');

    my $node = $ll->remove(8);
    is($ll->count, 11, '... count is 11 again');

    ok(!$node->get_next, '... detached node does not have a next');
    ok(!$node->get_previous, '... detached node does not have a previous');
    is($node->get_value, 6, '... detached node has the right value');
    ok($node->isa('LinkedListNode'), '... node is a LinkedListNode');

    eval { $ll->remove(99) };
    like($@, qr/^Index \(99\) out of bounds/, '... removing out of range produced error');
    eval { $ll->insert(-1, LinkedListNode->new('value' => 2)) };
    like($@, qr/^Index \(-1\) out of bounds/, '... inserting out of range produced error');

    is($ll->sum, 49, '... things sum correctly');
}

done_testing;
