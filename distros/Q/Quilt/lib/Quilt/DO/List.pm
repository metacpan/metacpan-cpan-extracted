#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: List.pm,v 1.1.1.1 1997/10/22 21:35:08 ken Exp $
#

use Quilt;

use strict;

package Quilt::DO::List;

sub first_item_num {
    my $self = shift;
    my $number = 1;

#    $number = $self->prev_with(sub {$node->is_list})->last_item_num
#	if (defined $self->continued);

    return $number;
}

sub last_item_num {
    my $self = shift;
#    my $number = $self->first_item_num;

#    return $number + $self->num_contents + 1;
}

package Quilt::DO::List::Iter;

sub last_item_num {
    my $self = shift;
    return ($self->[0]->last_item_num (@_));
}

sub first_item_num {
    my $self = shift;
    return ($self->[0]->first_item_num (@_));
}

package Quilt::DO::List::Item;

sub number {
    my $self = shift;
    my $real_self = $self->delegate;
    my $number = $self->parent->first_item_num;

    my $contents = $self->parent->contents();
    my $ii;
    for ($ii = 0; $ii <= $#$contents; $ii ++) {
	last if $contents->[$ii] == $real_self;

	$number ++
	    if (ref ($contents->[$ii]) eq 'Quilt::DO::List::Item');
    }

    return $number;
}

package Quilt::DO::List::Item::Iter;

# XXX support in Class::Visitor
sub number { goto &Quilt::DO::List::Item::number; }

package Quilt::DO::List::Term;

1;
