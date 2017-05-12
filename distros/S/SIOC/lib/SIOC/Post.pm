###########################################################
# SIOC::Post
# Post class for the SIOC ontology
###########################################################
#
# $Id: Post.pm 10 2008-03-01 21:38:39Z geewiz $
#

package SIOC::Post;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Moose;
use MooseX::AttributeHelpers;

extends 'SIOC::Item';

### required attributes

has 'content' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

has 'encoded_content' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

### optional attributes

has 'attachments' => (
    metaclass => 'Collection::Hash',
    isa => 'HashRef[Str]',
    is => 'rw',
    default => sub { {} },
    provides => {
        'set' => 'set_attachment',
        'get' => 'get_attachment',
    },
);

has 'related' => (
    isa => 'ArrayRef[SIOC::Item]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_related',
    },
);

has 'siblings' => (
    isa => 'ArrayRef[SIOC::Item]',
    metaclass => 'Collection::Array',
    is => 'rw',
    default => sub { [] },
    provides => {
        'push' => 'add_sibling',
    },
);

has 'note' => (
    isa => 'Str',
    is => 'rw',
);

has 'reply_count' => (
    isa => 'Num',
    is => 'rw',
);


### methods

# add additional template variables
after 'fill_template' => sub {
    my ($self) = @_;
    
    $self->set_template_vars({
        content => $self->content,
        encoded_content => $self->encoded_content
    });
};

1;

__DATA__
__rdfoutput__
<sioc:Post rdf:about="[% url | url %]">
    [% IF title %]
    <dc:title>[% name %]</dc:title>
    [% END %]
    [% IF creator %]
    <sioc:has_creator>
        <sioc:User rdf:about="[% creator.url | url %]">
            <rdfs:seeAlso rdf:resource="[% creator.export_url | url %]"/>
        </sioc:User>
    </sioc:has_creator>
    <foaf:maker>
        <foaf:Person rdf:about="[% creator.foaf_uri | url %]">
            <rdfs:seeAlso rdf:resource="[% creator.export_url | url %]"/>
        </foaf:Person>
    </foaf:maker>
    [% END %]

    <dcterms:created>[% created %]</dcterms:created>
    [% IF updated && created != updated %]
    <dcterms:modified>[% modified %]</dcterms:modified>
    [% END %]

    <sioc:content>[% content %]</sioc:content>
    <content:encoded><![CDATA[[% encoded_content %]]]></content:encoded>
    
    [% FOREACH topic = topics %]
    <sioc:topic rdfs:label="[% topic.name %]" rdf:resource="[% topic.url | url %]"/>
    [% END %]

    [% FOREACH link = links %]
    <sioc:links_to rdfs:label="[% link.name %]" rdf:resource="[% link.url | url %]"/>
    [% END %]
    
    [% FOREACH parent = parents %]
    <sioc:reply_of>
        <sioc:Post rdf:about="[% parent.url | url %]">
            <rdfs:seeAlso rdf:resource="[% parent.export_url | url %]"/>
        </sioc:Post>
    </sioc:reply_of>
    [% END %]
    
    [% FOREACH reply = replies %]
    <sioc:has_reply>
        <sioc:Post rdf:about="[% reply.url | url %]">
            <rdfs:seeAlso rdf:resource="[% reply.export_url | url %]"/>
        </sioc:Post>
    </sioc:has_reply>
    [% END %]
    
</sioc:Post>
__END__
    
=head1 NAME

SIOC::Post - SIOC Post class

=head1 VERSION

This documentation refers to SIOC::Post version 1.0.0.

=head1 SYNOPSIS

   use SIOC::Post;

=head1 DESCRIPTION

A Post is an article or message posted by a User to a Forum. A series of Posts
may be threaded if they share a common subject and are connected by reply or
by date relationships. Posts will have content and may also have attached
files, which can be edited or deleted by the Moderator of the Forum that
contains the Post.

The SIOC Types Ontology Module describes some additional, more specific
subclasses of SIOC::Post.

=head2 Class attributes

=over

=item content 

The content of the Post in plain text format.

This attribute is required and must be set in the creation of a class instance
with new().

=item encoded_content

Used to describe the encoded content of a Post, contained in CDATA areas.

This attribute is required and must be set in the creation of a class instance
with new().

=item attachments 

The URIs of files attached to a Post.

=item related

Related Posts for this Post, perhaps determined implicitly
from topics or references.

=item siblings

A Post may have a sibling or a twin that exists in a different
Forum, but the siblings may differ in some small way (for example, language,
category, etc.). The sibling of this Post should be self-describing (that is,
it should contain all available information).

=item note 

A note associated with this Post, for example, if it has been
edited by a User.

=item reply_count 

The number of replies that this Post has. Useful for when
the reply structure is absent.

=back


=head1 SUBROUTINES/METHODS

=head2 content([$content])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 encoded_content([$content])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 set_attachment($name => $data)

Sets a key/value pair in the corresponding hash attribute.

=head2 get_attachment($name)

Queries a key/value pair in the corresponding hash attribute.

=head2 add_related($item)

Adds a new value to the corresponding array attribute.

=head2 add_sibling($item)

Adds a new value to the corresponding array attribute.

=head2 note([$note])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 reply_count([$num])

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