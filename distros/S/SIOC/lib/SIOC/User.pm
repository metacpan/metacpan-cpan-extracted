###########################################################
# SIOC::User
# User class for the SIOC ontology
###########################################################
#
# $Id: User.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::User;

use strict;
use warnings;
use Carp;
use Data::Dumper qw( Dumper );

use version; our $VERSION = qv(1.0.0);

use Moose;
use MooseX::AttributeHelpers;

extends 'SIOC';

### required attributes

has 'email' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);
    
has 'foaf_uri' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
    );

### optional attributes

has 'email_sha1' => (
    isa => 'Str',
    is => 'rw',
);

has 'account_of' => (
    is => 'rw',
);

has 'avatar' => (
    is => 'rw',
);

has 'function' => (
    isa => 'ArrayRef[SIOC::Role]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_function',
    },
);

has 'usergroups' => (
    isa => 'ArrayRef[SIOC::Usergroup]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_usergroup',
    },
);

has 'created_items' => (
    isa => 'ArrayRef[SIOC::Item]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_created_forum',
    },
);

has 'modified_items' => (
    isa => 'ArrayRef[SIOC::Item]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_modified_forum',
    },
);

has 'administered_sites' => (
    isa => 'ArrayRef[SIOC::Site]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_administered_site',
    },
);

has 'moderated_forums' => (
    isa => 'ArrayRef[SIOC::Forum]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_moderated_forum',
    },
);

has 'owned_containers' => (
    isa => 'ArrayRef[SIOC::Container]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_owned_container',
    },
);

has 'subscriptions' => (
    isa => 'ArrayRef[SIOC::Container]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_subscription',
    },
);

### methods

after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_var(name => $self->name);
    $self->set_template_var(email => $self->email); 
    $self->set_template_var(foaf_uri => $self->foaf_uri);
    $self->set_template_var(email_sha1 => $self->email_sha1);
    $self->set_template_var(avatar => $self->avatar);
};

1;

__DATA__
__rdfoutput__
<foaf:Person rdf:about="[% foaf_uri | url %]">
[% IF name %]
    <foaf:name>[% name %]</foaf:name>
[% END %]
[% IF email_sha1 %]
    <foaf:mbox_sha1sum>[% email_sha1 %]</foaf:mbox_sha1sum>
[% END %]
    <foaf:holdsAccount>
        <sioc:User rdf:about="[% url | url %]">
[% IF nick %]
            <sioc:name>[% name %]</sioc:name>
[% END %]
[% IF email %]
            <sioc:email rdf:resource="[% email %]"/>
[% END %]
[% IF email_sha1 %]
            <sioc:email_sha1>[% email_sha1 %]</sioc:email_sha1>
[% END %]
[% IF role %]
            <sioc:has_function>
                <sioc:Role>
                    <sioc:name>[% role %]</sioc:name>
                </sioc:Role>
            </sioc:has_function>
[% END %]
        </sioc:User>  
    </foaf:holdsAccount>
</foaf:Person>
__END__
    
=head1 NAME

SIOC::User -- SIOC User class


=head1 VERSION

This documentation refers to SIOC::User version 1.0.0.


=head1 SYNOPSIS

   use SIOC::User;


=head1 DESCRIPTION

A User is an online account of a member of an online community. It is
connected to Items and Posts that a User creates or edits, to Containers and
Forums that it is subscribed to or moderates and to Sites that it administers.
Users can be grouped for purposes of allowing access to certain Forums or
enhanced community site features (weblogs, webmail, etc.).

A foaf:Person will normally hold a registered User account on a Site (through
the property foaf:holdsAccount), and will use this account to create content
and interact with the community.

sioc:User describes properties of an online account, and is used in
combination with a foaf:Person (using the property sioc:account_of) which
describes information about the individual itself.


=head1 CLASS ATTRIBUTES

=over

=item email 

An electronic mail address of the User.

=item foaf_uri

Link to a FOAF record.

=item email_sha1 

An electronic mail address of the User, encoded using SHA1.

=item account_of 

Refers to the foaf:Agent or foaf:Person who owns this sioc:User
online account.

=item avatar 

An image or depiction used to represent this User.

=item functions

Roles that this User has.

=item usergroups

A Usergroup that this User is a member of.

=item created_items 

Items that the User is a creator of.

=item modified_items 

Items that this User has modified.

=item administered_sites

Sites that the User is an administrator of.

=item moderated_forums 

Forums that User is a moderator of.

=item owned_containers 

Containers owned by a particular User, for example, a weblog or image gallery.

=item subscriptions 

Containers that a User is subscribed to.

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