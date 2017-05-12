package Net::DAV::LockManager::Simple;

use Net::DAV::Lock;

use strict;

our $VERSION = '1.305';
$VERSION = eval $VERSION;

#
# This reference implementation of the lock management database interface
# provides an example of the simplest case of a pluggable lock management
# backend mechanism which can be swapped in for any other sort of
# implementation without concern for the operation of the lock manager
# itself.
#

#
# Create a new lock manager context.  Optionally accepts an array
# containing a default set of locks.
#
sub new {
    my $class = shift;

    return bless \@_, $class;
}

#
# Stub method.  Simply present to adhere to the lock management interface
# used within this package.
#
sub close {
    return;
}

#
# Given a normalized string representation of a resource path, return
# the first lock found.  Otherwise, return undef if none is located.
#
sub get {
    my ($self, $path) = @_;

    foreach my $lock (@$self) {
        if ($lock->path eq $path) {
            return $lock;
        }
    }

    return undef;
}

#
# Given a path string, return all objects indexed whose path is a descendant
# of the one specified.
#
sub list_descendants {
    my ($self, $path) = @_;

    return grep { $_->path ne '/' } @$self if $path eq '/';
    return grep { index($_->path, "$path/") == 0 } @$self;
}

#
# Given a Net::DAV::Lock object, replace any other locks whose
# path corresponds to that which is stored in the list.
#
sub update {
    my ($self, $lock) = @_;

    for (my $i=0; $$self[$i]; $i++) {
        if ($$self[$i]->path eq $lock->path) {
            $$self[$i] = $lock;
        }
    }

    return $lock;
}

#
# Add the given lock object to the list.
#
sub add {
    my ($self, $lock) = @_;

    push @$self, $lock;

    return $lock;
}

#
# Given a lock, the database record which contains the corresponding
# path will be removed.
#
sub remove {
    my ($self, $lock) = @_;

    @{$self} = grep { $_->path ne $lock->path } @{$self};
}

1;

__END__
Copyright (c) 2010, cPanel, Inc. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
