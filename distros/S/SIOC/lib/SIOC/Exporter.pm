###########################################################
# SIOC::Exporter
# Exporter class for the SIOC ontology
###########################################################
#
# $Id: Exporter.pm 21 2008-03-21 17:45:07Z geewiz $
#

package SIOC::Exporter;

use strict;
use warnings;

use version; our $VERSION = qv(1.0.0);

use Moose;
use MooseX::AttributeHelpers;
use Carp;

# singleton Template::Provider for this class
my $template_provider = Template::Provider::FromDATA->new({
    CLASSES => __PACKAGE__,
});

### required attributes

has 'host' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

### optional attributes

has 'encoding' => (
    isa => 'Str',
    is => 'ro',
    default => sub { 'utf-8' },
);
has 'generator' => (
    isa => 'Str',
    is => 'ro',
    default => sub { 'perl-SIOC' },
);
has 'export_email' => (
    isa => 'Str',
    is => 'ro',
    default => sub { 0 },
);
    
### internal attributes

has '_object' => (
    isa => 'SIOC',
    is => 'rw',
);
has '_url' => (
    isa => 'Str',
    is => 'ro',
    default => sub { 'http://wiki.sioc.org/...' },
);
has '_version' => (
    isa => 'Str',
    is => 'ro',
    default => sub { "$VERSION" },    
);

### methods

sub _init_template {
    my ($self) = @_;

    # create new Template object
    my $template = Template->new({
        LOAD_TEMPLATES => [ 
            $template_provider,
        ]
    });

    return $template;
}

sub register_object {
    my ($self, $object) = @_;
    
    my $export_url = $self->object_export_url($object);
    $object->export_url($export_url);
    
    return $export_url;
}

sub export_object {
    my ($self, $object) = @_;
    
    $self->_object($object);
    
    return 1;
};

sub object_export_url {
    my ($self, $object) = @_;
    
    my $url = sprintf("%s/sioc.pl?class=%s&id=%s", 
        $self->host,
        $object->type, 
        $object->id
    );

    return $url;
}

sub output {
    my ($self) = @_;

    # prepare template engine
    my $template = $self->_init_template();
    my $output;

    my $object_rdf = q();

    # set object url attribute
    $self->_object->export_url($self->object_export_url($self->_object));

    # fill template variables
    my $template_vars = {
        encoding => $self->encoding,
        exporter_url => $self->_url,
        exporter_version => $VERSION,
        exporter_generator => 'perl-SIOC',
        object => $self->_object,
    };

    # process template
    my $ok = $template->process('rdfoutput', $template_vars, \$output);
    if (! $ok) {
        croak $template->error();
    }

    return $output;
}

1;
__DATA__
__rdfoutput__
Content-Type: application/rdf+xml; charset=[% encoding %]

<?xml version="1.0" encoding="[% encoding %]" ?>
<rdf:RDF
    xmlns="http://xmlns.com/foaf/0.1/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:admin="http://webns.net/mvcb/"
    xmlns:content="http://purl.org/rss/1.0/modules/content/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:sioc="http://rdfs.org/sioc/ns#">

<foaf:Document rdf:about="">
	<dc:title>SIOC profile for [% object.name %]</dc:title>
	<dc:description>A SIOC profile describes the structure and contents of a community site (e.g., weblog) in a machine processable form. For more information refer to the <a href="http://rdfs.org/sioc">SIOC project page</a>'></dc:description>
	<foaf:primaryTopic rdf:resource="[% object.url | url %]"/>
	<admin:generatorAgent rdf:resource="[% exporter_url | url %]?version=[% exporter_version | uri %]"/>
	<admin:generatorAgent rdf:resource="[% exporter_generator %]"/>
</foaf:Document>

[% IF rdf_content %][% rdf_content %][% END %]

[% IF object %]
<!-- type: [% object.type %], id: [% object.id %] -->
[% object.export_rdf %]
[% END %]

</rdf:RDF>
__END__

=head1 NAME

SIOC::Exporter -- SIOC RDF exporter class


=head1 VERSION

This documentation refers to SIOC::Exporter version 1.0.0.


=head1 SYNOPSIS

   use SIOC::Exporter;
   
   # create SIOC object instance, e.g. a SIOC::User
   use SIOC::User;
   my $user = SIOC::User->new(...);

   # create exporter instance
   my $exporter = SIOC::Exporter->new({
       host => 'http://www.example.com',
   });

   # pass object to exporter
   $exporter->export_object($user);
   
   # output the object's information as RDF data
   print $exporter->output(), "\n";
   

=head1 DESCRIPTION

This module implements a SIOC exporter class. It will output the RDF
representation of SIOC objects passed to it.


=head1 ATTRIBUTES

=over

=item host

The host attribute stores the URL of the website whose information is
exported.

This attribute is required and must be set in the creation of a class instance
with new().

=item encoding

The encoding attribute stores the character encoding used. This information
will be used in the XML processing instruction and in the charset header
generated by the output() method.

=item generator

The generator attribute stores the identification of the software using
SIOC::Exporter to generate SIOC information.

=item export_email

The export_email attribute stores a boolean value that determines if email
addresses will be included in the RDF output.

=back


=head1 SUBROUTINES/METHODS

=head2 new(\%attributes)

Creates a new class instance. Arguments are passed as a hash reference. See
the ATTRIBUTES section above for required arguments.

=head2 register_object($sioc_object)

This method registers a SIOC object with the exporter, assigning a SIOC
exporter URL to it. This URL is necessary to reference the object in RDF.

=head2 export_object

Pass the SIOC object you want to export with output() as an argument to this
method.

=head2 object_export_url

This method generates the URL at which the SIOC data of the object passed as
an argument will be provided. It's used by register_object().

Change this method in a derived subclass to reflect your website
configuration.

=head2 output


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