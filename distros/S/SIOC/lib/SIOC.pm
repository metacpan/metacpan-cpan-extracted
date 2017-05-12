###########################################################
# SIOC
# Base class for the SIOC ontology
###########################################################
#
# $Id: SIOC.pm 22 2008-03-21 18:01:41Z geewiz $
#

package SIOC;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Carp;
use Readonly;
use Template;
use Template::Provider::FromDATA;
use Data::Dumper qw( Dumper );
use Moose;
use MooseX::AttributeHelpers;

# singleton hash of Template::Provider for the SIOC classes 
my %template_provider;

### required attributes

has 'id' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);
has 'name' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);
has 'url' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);
    
### optional attributes

has 'description' => (
    isa => 'Str',
    is => 'rw',
);
has 'comment' => (
    isa => 'Str',
    is => 'rw',
);
has 'topics' => (
    isa => 'ArrayRef[Str]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_topic',
    },
);
has 'feed' => (
    isa => 'ArrayRef[Str]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_feed'
    },
);
has 'links' => (
    isa => 'ArrayRef[Str]',
    metaclass => 'Collection::Array',
    is => 'rw',
    provides => {
        'push' => 'add_link'
    },
);
has 'export_url' => (
    isa => 'Str',
    is => 'rw',
);

### internal attributes

has '_template_vars' => (
    isa => 'HashRef',
    metaclass => 'Collection::Hash',
    is => 'rw',
    default => sub { {} },
    provides => {
        'set' => 'set_template_var',
    },
);
    
### methods

sub _init_template {
    my ($self) = @_;

    # get template provider
    my $class_name = ref $self;
    if (! exists $template_provider{$class_name}) {
        # create T::Provider for this class
        $template_provider{$class_name} 
          = Template::Provider::FromDATA->new({
            CLASSES => $class_name,
        })
    }
    my $provider = $template_provider{$class_name};
    
    # create new Template object
    my $template = Template->new({
        LOAD_TEMPLATES => [ 
            $provider,
        ]
    });

    return $template;
}

sub type {
    my ($self) = @_;
    
    my $type = ref $self;
    $type =~ s/SIOC:://xms;
    $type =~ tr/A-Z/a-z/;
    
    return $type;
}

sub set_template_vars {
    my ($self, $vars) = @_;
    
    foreach my $varname (keys %{$vars}) {
        $self->set_template_var($varname => $vars->{$varname});
    } 
    
    return 1;
}

sub fill_template {
    my ($self) = @_;

    $self->set_template_vars({
        export_url => $self->export_url,
        id => $self->id,
        name => $self->name,
        url => $self->url,
        description => $self->description,
        comment => $self->comment
    });
    
    return 1;
}

sub export_rdf {
    my ($self) = @_;
    
    if (! defined $self->export_url) {
        croak "Object not registered with SIOC::Exporter!\n";
    }
    
    my $template = $self->_init_template();
    $self->fill_template();
    
    my $output;
    $template->process('rdfoutput', $self->_template_vars, \$output) 
        || croak $template->error();
    $output =~ s/\s+$//xmsg;
    
    return $output;
}

1;
__DATA__
__rdfoutput__
<sioc:Object>
    <rdfs:comment>Generic SIOC Object named [% name %]</rdfs:comment>
</sioc:Object>
__END__

=head1 NAME

SIOC -- The SIOC Core Ontology

=head1 VERSION

This documentation refers to SIOC version 1.0.0.

=head1 SYNOPSIS

This is an abstract class that isn't meant to be instantiated.

=head1 DESCRIPTION

The SIOC (Semantically-Interlinked Online Communities) Core Ontology provides
the main concepts and properties required to describe information from online
communities (e.g., message boards, wikis, weblogs, etc.) on the Semantic Web.

This distribution implements the various SIOC subclasses like SIOC::Site,
SIOC::User, SIOC::Forum or SIOC::Post. It also contains an exporter class
(SIOC::Exporter) that Perl-based community software can use to generate a
semantic RDF representation of its data.

This class implements an abstract base class for the various SIOC subclasses
like

=over

=item *

SIOC::Site

=item *

SIOC::User

=item *

SIOC::Forum

=back

(See the module's distribution for a complete list of modules.)

The SIOC::Exporter module implements a class that can be used to export
SIOC information as RDF data.

=head1 CLASS ATTRIBUTES

=over

=item id 

An identifier of a SIOC concept instance. For example, a user ID.
Must be unique for instances of each type of SIOC concept within the same
site.

This attribute is required and must be set in the creation of a class instance
with new().

=item name 

The name of a SIOC instance, e.g. a username for a User, group
name for a Usergroup, etc.

This attribute is required and must be set in the creation of a class instance
with new().

=item url

The URL of this resource on the Web.

This attribute is required and must be set in the creation of a class instance
with new().

=item description

A textual description of the resource.

=item comment

A comment on the SIOC instance.

=item topics

Topics the resource is connected to.

=item feeds 

Feeds (e.g., RSS, Atom, etc.) pertaining to this resource (e.g.,
for a Forum, Site, User, etc.).

=item links 

URIs of documents which contain this SIOC object.

=back


=head1 SUBROUTINES/METHODS

=head2 new(\%args)

Creates a new class instance. Arguments are passed as a hash reference. See
the ATTRIBUTES section above for required arguments.

=head2 id([$new_id])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 name([$new_name])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 url([$newurl])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 description([$newdescription])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 comment([$comment])

Accessor for the attribute of the same name. Call without argument to read the
current value of the attribute; sets attribute when called with new value as
argument.

=head2 add_topic($newtopic)

Adds a new value to the corresponding array attribute.

For $newtopic, a string is expected.

=head2 add_feed($newfeed)

Adds a new value to the corresponding array attribute.

For $newfeed, a string is expected.

=head2 add_link($newlink)

Adds a new value to the corresponding array attribute.

For $newlink, a string is expected.

=head2 type()

Returns a string representation of the SIOC subclass. For an instance of
SIOC::Forum, it returns 'forum', for SIOC::Post 'post' and so on.

=head2 export_rdf()

Returns the object's information in RDF format.

=head2 fill_template

This method is called by export_rdf() to provide template variables needed by
Template Toolkit. Use the set_template_vars method for each variable.

It always returns 1.

=head2 set_template_vars(\%vars)

Set template variables from the key/value pairs of the hash reference passed
as an argument.


=head1 DIAGNOSTICS

For diagnostics information, see the SIOC base class.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

This module depends on the following modules:

=over

=item *

Moose -- OOP framework

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