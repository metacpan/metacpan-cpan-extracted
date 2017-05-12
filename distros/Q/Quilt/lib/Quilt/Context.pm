#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Context.pm,v 1.1.1.1 1997/10/22 21:35:08 ken Exp $
#

use strict;

package Quilt::Context;

sub copy {
    my ($self) = @_;
    my ($key, $value);
    my ($new_current) = {};

    while (($key, $value) = each %{$self->{'current'}[-1]}) {
	$new_current->{$key} = $value;
    }

    return $new_current;
}

sub push {
    my ($self, $obj) = @_;
    my ($key, $value, $new);

    $new = $self->copy;
    if (ref ($obj) =~ /::Iter$/) {
	$obj = $obj->delegate;
    }

    while (($key, $value) = each %$obj) {
	next if $key eq 'contents';
	$new->{$key} = $value;
    }
    push (@{$self->{'current'}}, $new);
}

sub pop {
    my ($self) = @_;

    pop (@{$self->{'current'}});
}

1;
