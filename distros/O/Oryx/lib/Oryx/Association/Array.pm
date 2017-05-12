package Oryx::Association::Array;

use base qw(Oryx::Association);

our $DEBUG = 0;

=head1 NAME

Oryx::Association::Array - Abstract Array association meta-type for Oryx

=head1 DESCRIPTION

Abstract Array association meta-type for Oryx.

The actual array which is kept internally is a list of L<Oryx::Association::Reference>
instances.

This module implements a private C<tie> interface for Arrays 
which is shared accross all Array association
implementation classes (L<Oryx::DBI::Association::Array>, for example)
as well as an abstract public interface used when subclassing.

=head1 PUBLIC INTERFACE

=over

=item load

loads the data from storage - with DBI style storage, this does a select
on the link table to build up the array of L<Oryx::Association::Reference>
instances.

=item fetch

used by FETCH (see L<perltie>)

=item store

used by STORE (see L<perltie>)

=back

=cut

sub new {
    my ($class, $proto) = @_;
    return bless $proto, $class;
}

sub load  { $_[0]->_croak('abstract') }
sub fetch { $_[0]->_croak('abstract') }
sub store { $_[0]->_croak('abstract') }

#=============================================================================
# TIE MAGIC
sub TIEARRAY {
    my ($class, $meta, $owner) = @_;

    my $self = bless {
	meta  => $meta,
	owner => $owner, # the object instance which owns this Value
        created => { },
        deleted => { },
        updated => { },
    }, $class;

    return $self;
}

sub ARRAY {
    my ($self) = @_;
    unless (defined $self->{ARRAY}) {
	$self->{ARRAY} = $self->{meta}->load($self->{owner});
    }
    $self->{ARRAY};
}

sub FETCH {
    my ($self, $index) = @_;
    if ($index >= 0) {
	return $self->{meta}->fetch($self->ARRAY->[$index], $self->{owner});
    } else {
	return undef;
    }
}

sub STORE {
    my ($self, $index, $thing) = @_;

    $DEBUG && $self->_carp("STORE $index : ".$self->FETCHSIZE." : $thing");
    if ($index >= $self->FETCHSIZE()) {
	$self->_set_created($index, $thing);
	if ($index > $self->FETCHSIZE()) {
	    $self->EXTEND($index);
	}
    } else {
	$self->_set_updated($index, $thing);
    }

    $self->ARRAY->[$index] = $self->{meta}->store($thing, $self->{owner});
}

sub FETCHSIZE {
    my $self = shift;
    return scalar @{$self->ARRAY};
}

sub STORESIZE {
    my $self  = shift;
    my $count = shift;
    if ($count > $self->FETCHSIZE()) {
	foreach ($count - $self->FETCHSIZE() .. $count) {
	    $self->STORE($_-1, undef) unless defined $self->ARRAY->[$_-1];
	}
    } elsif ($count < $self->FETCHSIZE()) {
	foreach (0 .. $self->FETCHSIZE() - $count - 2) {
	    $self->POP();
	}
    }
}

sub EXTEND {
    my $self  = shift;
    my $count = shift;
    $self->STORESIZE( $count );
}

sub EXISTS {
    my $self  = shift;
    my $index = shift;
    return exists $self->ARRAY->[$index];
}

sub DELETE {
    my $self  = shift;
    my $index = shift;
    $self->_set_deleted($index, $self->ARRAY->[$index]);
    delete $self->ARRAY->[$index];
    return $self->FETCH($index);
}

sub CLEAR {
    my $self = shift;
    my $index = 0;
    while (@{$self->ARRAY}) {
	$self->DELETE($index);
	shift @{$self->ARRAY};
	$index++;
    }
}

sub PUSH {
    my $self = shift;
    my @list = @_;
    my $last = $self->FETCHSIZE();
    $self->STORE( $last + $_, $list[$_] ) foreach 0 .. $#list;
    return $self->FETCHSIZE();
}

sub POP {
    my $self = shift;
    my $index = $self->FETCHSIZE() - 1;
    my $thing = $self->FETCH($index);
    $self->_set_deleted($index, $thing);
    pop @{$self->ARRAY};
    return $thing;
}

sub SHIFT {
    my $self = shift;
    my $thing = $self->FETCH(0);
    for (my $x = 1; $x < $self->FETCHSIZE(); $x++) {
	$self->STORE($x - 1, $self->ARRAY->[$x]);
    }
    $self->POP();
    return $thing;
}

sub UNSHIFT {
    my $self = shift;
    my @list = @_;
    my $size = scalar( @list );
    my $old_size = $self->FETCHSIZE();

    # make room for our list
    $self->STORESIZE($old_size + $size);

    # shift everything up from the end
    for (my $x = $#{$self->ARRAY}; $x >= $size; $x--) {
	$self->STORE($x, $self->ARRAY->[$x - $size]);
    }

    # store the new values
    $self->STORE($_, $list[$_]) foreach 0 .. $#list;
}

sub SPLICE {
    my $self   = shift;
    my $offset = shift || 0;
    my $length = defined $_[0] ? shift : $self->FETCHSIZE() - $offset;

    my @list = @_;

    my @removed;

    # new total length ==
    #   current size + length of inserted list - length of splice
    my $old_size = $self->FETCHSIZE();
    my $new_size = $old_size + scalar(@list) - $length;

    # grab any removed items
    push @removed, $self->FETCH($_) foreach ($offset .. $offset + $length);

    # if the new array is longer than the current size, move existing
    # elements right by the delta starting at the end
    my $delta = $new_size - $old_size;
    if ($delta > 0) {
	$self->STORESIZE($new_size);
	for (my $x = $new_size - 1; $x > $offset; $x--) {
	    $self->STORE($x, $self->ARRAY->[$x - $delta]);
	}
    }
    # else if new array is shorter, move existing elements left
    # starting at offset + length and remove unused slots from the end
    elsif ($delta < 0) {
	for (my $x = $length + $delta; $x < $old_size; $x++) {
	    $self->STORE($x, $self->ARRAY->[$x - $delta]);
	}
	$self->STORESIZE($new_size - 1);
    }

    # store the inserted list starting at offset
    $self->STORE($_ + $offset, $list[$_]) foreach 0 .. $#list;

    # update all if the length has changed
    if (abs($delta)) {
	$self->_set_updated($_, $self->ARRAY->[$_])
	  foreach 0 .. $#{$self->ARRAY};
    }

    return @removed;
}

sub created { $_[0]->{created} = $_[1] if $_[1]; $_[0]->{created} };
sub updated { $_[0]->{updated} = $_[1] if $_[1]; $_[0]->{updated} };
sub deleted { $_[0]->{deleted} = $_[1] if $_[1]; $_[0]->{deleted} };

# try to keep the database operations to a minimum...
sub _set_deleted {
    my ($self, $index, $thing) = @_;
    delete $self->updated->{$index} if $self->updated->{$index};
    if ($self->created->{$index}) {
	delete $self->created->{$index};
    } else {
	$self->deleted->{$index} = $thing;
    }
}

sub _set_created {
    my ($self, $index, $thing) = @_;
    if ($self->deleted->{$index}) {
	$self->updated->{$index} = $thing;
	delete $self->deleted->{$index};
    } else {
	$self->created->{$index} = $thing;
    }
}

sub _set_updated {
    my ($self, $index, $thing) = @_;
    delete $self->deleted->{$index} if $self->deleted->{$index};
    if ($self->created->{$index}) {
	$self->created->{$index} = $thing;
    } else {
	$self->updated->{$index} = $thing;
    }
}

1;

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>, L<Oryx::Association>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
