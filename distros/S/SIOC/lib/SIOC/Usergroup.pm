###########################################################
# SIOC::Usergroup
# Usergroup class for the SIOC ontology
###########################################################
#
# $Id: Usergroup.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::Usergroup;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Moose;

extends 'SIOC';

### required attributes

has members => (
    isa => 'ArrayRef[SIOC::User]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_member',
    },
    required => 1,
);
    
### optional attributes

# parent space
has 'spaces' => (
    isa => 'ArrayRef[SIOC::Space]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_space',
    },
);

### methods

after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_var(members => $self->members);
    $self->set_tempalte_var(space => $self->space);
};

### EOC

1;
__END__
    
=head1 NAME

SIOC::Usergroup -- SIOC Usergroup class

=head1 VERSION

This documentation refers to SIOC::Usergroup version 1.0.0.


=head1 SYNOPSIS

   use SIOC::Usergroup;


=head1 DESCRIPTION

A Usergroup is a set of members or Users of a community who have a common
Role, purpose or interest. While a group of Users may be a single community
that is linked to a certain Forum, they may also be a set of Users who perform
a certain Role, for example, moderators or administrators.


=head1 CLASS ATTRIBUTES

=over

=item members 

User who are members of this Usergroup.

=item spaces 

Spaces that the Usergroup has access to.

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