###########################################################
# SIOC::Item
# Item class for the SIOC ontology
###########################################################
#
# $Id: Item.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::Item;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Moose;
use MooseX::AttributeHelpers;

extends 'SIOC';

### required attributes

has 'created' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

has 'creator' => (
    isa => 'SIOC::User',
    is => 'rw',
    required => 1,
);

### optional attributes

has 'modified' => (
    isa => 'Str',
    is => 'rw'
);

has 'modifier' => (
    isa => 'SIOC::User',
    is => 'rw',
);

has 'view_count' => (
    isa => 'Num',
    is => 'rw',
);

has 'about' => (
    isa => 'Str',
    is => 'rw',
);

has 'container' => (
    isa => 'SIOC::Container',
    is => 'rw',
);

has 'parent_posts' => (
    isa => 'ArrayRef[SIOC::Item]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_parent_post',
    },
);

has 'reply_posts' => (
    isa => 'ArrayRef[SIOC::Item]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_reply_post',
    },
);

has 'ip_address' => (
    isa => 'Str',
    is => 'rw',
);

has 'previous_by_date' => (
    isa => 'SIOC::Item',
    is => 'rw',
);

has 'next_by_date' => (
    isa => 'SIOC::Item',
    is => 'rw',
    );

has 'previous_version' => (
    isa => 'SIOC::Item',
    is => 'rw',
);

has 'next_version' => (
    isa => 'SIOC::Item',
    is => 'rw',
);

### methods

after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_var(created => $self->created);
    $self->set_template_var(creator => $self->creator);
};

1;
__END__
    
=head1 NAME

SIOC::Item -- SIOC Item class

=head1 VERSION

The initial template usually just has:

This documentation refers to SIOC::Item version 0.0.1.

=head1 SYNOPSIS

   use <Module::Name>;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

SIOC::Item is a high-level concept for content items. It has subclasses that
further specify different types of Items. One of these subclasses (which plays
an important role in SIOC) is SIOC::Post, used to describe articles or messages
created within online community Sites. The SIOC Types Ontology Module
describes additional, more specific subclasses of sioc:Item.

Items can be contained within Containers.

=head1 CLASS ATTRIBUTES

=over

=item created 

Details the date and time when a resource was created.

This attribute is required and must be set in the creation of a class instance
with new().

=item creator 

This is the User who made this Item.

This attribute is required and must be set in the creation of a class instance
with new().

=item modified 

Details the date and time when a resource was modified.

=item modifier 

A User who modified this Item.

=item view_count 

The number of times this Item, Thread, User profile, etc. has been viewed.

=item about 

Specifies that this Item is about a particular resource, e.g., a Post
describing a book, hotel, etc.

=item container 

The Container to which this Item belongs.

=item parent_posts 

Links to Items or Posts which this Item or Post is a reply to.

=item reply_posts 

Points to Items or Posts that are a reply or response to this Item or Post.

=item ip_address 

The IP address used when creating this Item. This can be
associated with a creator. Some wiki articles list the IP addresses for the
creator or modifiers when the usernames are absent.

=item previous_by_date 

Previous Item or Post in a given Container sorted by date.

=item next_by_date 

Next Item or Post in a given Container sorted by date.

=item previous_version 

Links to a previous revision of this Item or Post.

=item next_version 

Links to the next revision of this Item or Post.

=back


=head1 SUBROUTINES/METHODS

=head2 created([$new_creation_date])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 creator([$new_creator])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 modified([$new_modified_date])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 modifier([$new_modifier])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 view_count($new_count)

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 about([$new_about])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 container([$new_container])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 add_parent_post($post)

Adds a new value to the corresponding array attribute.

=head2 add_reply_post

Adds a new value to the corresponding array attribute.

=head2 ip_address([$new_ip])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 previous_by_date([$post])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 next_by_date([%post])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 previous_version([$post])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 next_version([$post])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.


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