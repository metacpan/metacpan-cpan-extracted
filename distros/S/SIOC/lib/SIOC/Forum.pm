###########################################################
# SIOC::Forum
# Forum class for the SIOC ontology
###########################################################
#
# $Id: Forum.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::Forum;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Moose;
use MooseX::AttributeHelpers;

extends 'SIOC::Container';

### optional attributes

has 'host' => (
    isa => 'SIOC::Site',
    is => 'rw'
);

has 'moderators' => (
    isa => 'ArrayRef[SIOC::User]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_moderator'
    },
);

has 'scopes' => (
    isa => 'ArrayRef[SIOC::Role]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_scope'
    },
);

### methods

after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_var(host => $self->host);
    $self->set_template_var(moderators => $self->moderators);
    $self->set_template_var(scopes => $self->scopes);
};

1;
__DATA__
__rdfoutput__
<sioc:Forum rdf:about="[% url %]">
    <sioc:link rdf:resource="[% export_url %]"/>
[% IF title %]
    <dc:title>[% name %]</dc:title>
[% END %]
[% IF description %]
    <dc:description>[% description %]</dc:description>
[% END %]
[% IF comment %]
    <rdfs:comment>[% comment %]</rdfs:comment>
[% END %]

[% FOREACH thread = threads %]
    <sioc:parent_of>
        <sioc:Thread rdf:about="[% thread.url %]">
            <rdfs:seeAlso rdf:resource="[% thread.export_url %]"/>
        </sioc:Thread>
    </sioc:parent_of>
[% END %]

[% FOREACH post = items %]
    <sioc:container_of>
        <sioc:Post rdf:about="[% post.url %]">
            <rdfs:seeAlso rdf:resource="[% post.export_url %]"/>
        </sioc:Post>
    </sioc:container_of>
[% END %]

[% IF next_page_url %]
    <rdfs:seeAlso rdf:resource="[% next_page_url | url %]"/>
[% END %]
</sioc:Forum>
__END__
    
=head1 NAME

SIOC::Forum -- SIOC Forum class

=head1 VERSION

This documentation refers to SIOC::Forum version 1.0.0.

=head1 SYNOPSIS

   use SIOC::Forum;

=head1 DESCRIPTION

Forums can be thought of as channels or discussion area on which Posts are
made. A Forum can be linked to the Site that hosts it. Forums will usually
discuss a certain topic or set of related topics, or they may contain
discussions entirely devoted to a certain community group or organisation. A
Forum will have a moderator who can veto or edit posts before or after they
appear in the Forum.

Forums may have a set of subscribed Users who are notified when new Posts are
made. The hierarchy of Forums can be defined in terms of parents and children,
allowing the creation of structures conforming to topic categories as defined
by the Site administrator. Examples of Forums include mailing lists, message
boards, Usenet newsgroups and weblogs.

The SIOC Types Ontology Module defines come more specific subclasses of
SIOC::Forum.

=head1 CLASS ATTRIBUTES

=over

=item host 

The Site that hosts this Forum.

=item moderators 

Users who are moderators of this Forum.

=item scopes 

Roles that have a scope of this Forum.

=back


=head1 SUBROUTINES/METHODS

=head2 host([$new_host])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 add_moderator($new_moderator)

Adds a new value to the corresponding array attribute.

=head2 add_scope($new_scope)

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