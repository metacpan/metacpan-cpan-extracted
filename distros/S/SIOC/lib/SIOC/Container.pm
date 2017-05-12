###########################################################
# SIOC::Container
# Container class for the SIOC ontology
###########################################################
#
# $Id: Container.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::Container;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Moose;

extends 'SIOC';

### optional attributes

# parent container/forum
has 'parent' => (
    isa => 'SIOC::Container',
    is => 'rw',
    );

# child containers/forums
has 'children' => (
    isa => 'ArrayRef[SIOC::Container]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_child',
    },
    );

# contained items/posts
has 'items' => (
    isa => 'ArrayRef[SIOC::Item]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_item',
    },
    );

# user that owns this container
has 'owner' => (
    isa => 'SIOC::User',
    is => 'rw',
    );

# users that subscribe to this container
has 'subscribers' => (
    isa => 'ArrayRef[SIOC::User]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_subscriber',
    },
    );

### methods

after 'fill_template' => sub {
    my ($self) = @_;

    $self->set_template_var(parent => $self->parent);
    $self->set_template_var(children => $self->children);
    $self->set_template_var(items => $self->items);
    $self->set_template_var(owner => $self->owner);
    $self->set_template_var(subscribers => $self->subscribers);
};    
   
1;
__END__
    
=head1 NAME

SIOC::Container -- SIOC Container class

=head1 VERSION

This documentation refers to SIOC::Container version 1.0.0.

=head1 SYNOPSIS

   use SIOC::Container;

=head1 DESCRIPTION

Container is a high-level concept used to group content Items together. The
relationships between a Container and the Items that belong to it are
described using sioc:container_of and sioc:has_container properties. A
hierarchy of Containers can be defined in terms of parents and children using
sioc:has_parent and sioc:parent_of.

Subclasses of Container can be used to further specify typed groupings of
Items in online communities. Forum, a subclass of Container and one of the
core classes in SIOC, is used to describe an area on a community Site (e.g., a
forum or weblog) on which Posts are made. The SIOC Types Ontology Module
contains additional, more specific subclasses of SIOC::Container.


=head1 CLASS ATTRIBUTES

=over

=item parent 

A Container or Forum that this Container or Forum is a
child of.

=item children 

Child Containers or Forums that this Container or Forum is a
parent of.

=item items 

Items/Posts that this Container contains.

=item owner 

A User that this Container is owned by.

=item subscribers 

Users who are subscribed to this Container.

=back


=head1 SUBROUTINES/METHODS

=head2 parent([$new_parent])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 add_child($new_child)

Adds a new value to the corresponding array attribute.

=head2 add_item($new_item)

Adds a new value to the corresponding array attribute.

=head2 owner([$new_owner])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 add_subscriber($new_subscriber)

Adds a new value to the corresponding array attribute.


=head1 DIAGNOSTICS

For diagnostics information, see the SIOC base class.


=head1 CONFIGURATION AND ENVIRONMENT

This module doesn't need configuration.


=head1 DEPENDENCIES

This module depends on the following modules:

=over

=item *

Moose -- OOP framework (CPAN)

=item *

SIOC -- SIOC abstract base class (part of this module's distribution)

=back


=head1 INCOMPATIBILITIES

There are no known incompatibilities.


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems via the bug tracking system on the perl-SIOC project
website: L<http://developer.berlios.de/projects/perl-sioc/>.

Patches are welcome.

=head1 AUTHOR

Jochen Lillich <geewiz@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Jochen Lillich <geewiz@cpan.org>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * The names of its contributors may not be used to endorse or promote
      products derived from this software without specific prior written
      permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.