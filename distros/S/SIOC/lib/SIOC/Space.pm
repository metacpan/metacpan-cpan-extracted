###########################################################
# SIOC::Space
# Space class for the SIOC ontology
###########################################################
#
# $Id: Space.pm 10 2008-03-01 21:38:39Z geewiz $
#
package SIOC::Space;

use strict;
use warnings;

our $VERSION = do { if (q$Revision: 10 $ =~ /Revision: (?:\d+)/mx) { sprintf "1.0-%03d", $1; }; };

use Moose;
use MooseX::AttributeHelpers;

extends 'SIOC';

### optional attributes

has 'parent' => (
    isa => 'SIOC::Space',
    is => 'rw',
);

has 'space_of' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[SIOC]',
    default => sub { [] },
    provides => {
        'push' => 'make_space_of',
    },
);

has 'usergroups' => (
    isa => 'ArrayRef[SIOC::Usergroup]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_usergroup',
    },
);

### methods

after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_var(parent => $self->parent);
    $self->set_template_var(usergroups => $self->usergroups);
    $self->set_template_var(space_of => $self->space_of);
};

1;
__END__

=head1 NAME

SIOC::Space -- SIOC Space class


=head1 VERSION

This documentation refers to SIOC::Space version 1.0.0.


=head1 SYNOPSIS

   use SIOC::Space;


=head1 DESCRIPTION

A Space is defined as being a place where data resides. It can be the location
for a set of Containers of content Items, e.g., on a Site, personal desktop,
shared filespace, etc. Any data object that resides on a particular Space can
be linked to it using the sioc:has_space property.


=head1 CLASS ATTRIBUTES

=over

=item parent 

A data Space which this resource is a part of.

=item space_of 

A resource which belongs to this data Space.

=item usergroups 

Points to Usergroups that have certain access to this Space.

=back


=head1 SUBROUTINES/METHODS

TODO: document methods


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