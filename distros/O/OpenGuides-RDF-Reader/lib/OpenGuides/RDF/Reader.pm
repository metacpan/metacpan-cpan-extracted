package OpenGuides::RDF::Reader;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.05';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(parse_rdf);
    @EXPORT_OK   = qw(parse_rdf);
    %EXPORT_TAGS = (all => [qw(parse_rdf)]);
}

use XML::Simple;

sub parse_rdf {
    my $xml = shift;

    my $rdf = XMLin( $xml, 
    	ForceArray => [qw/foaf:based_near dc:subject/ ],
	GroupTags => {'dc:source' => 'rdf:resource',
			'foaf:homepage' => 'rdf:resource' },
	#NumericEscape => 2,
    );

    my $geo;
    my $desc = $rdf->{'rdf:Description'};
    if (ref $desc eq 'ARRAY') {
    	$geo = $desc->[1];
	$desc = $desc->[0];
    }
    else {
    	$geo = $rdf->{'geo:SpatialThing'};
    }
    
    my %descmap = (
    	username => 'dc:contributor',
	changed => 'dc:date',
	version => 'wiki:version',
	source => 'dc:source',
	);
    my %geomap = (
    	country => 'country',
	city => 'city',
	address => 'address',
	postcode => 'postalCode',
	phone => 'phone',
	fax => 'fax',
	website => 'foaf:homepage',
	opening_hours_text => 'chefmoz:Hours',
	longitude => 'geo:long',
	latitude => 'geo:lat',
	category => 'dc:subject',
	summary => 'dc:description',
	);
    my %out;
    $out{$_} = $desc->{$descmap{$_}} for keys %descmap;
    $out{$_} = $geo->{$geomap{$_}} for keys %geomap;
    $out{locale} = [ map {$_->{'wn:Neighborhood'}{'foaf:name'}}
    	@{$geo->{'foaf:based_near'}} ] if exists $geo->{'foaf:based_near'};

    %out;
}

=head1 NAME

OpenGuides::RDF::Reader - Parse and return OpenGuides metadata from RDF

=head1 SYNOPSIS

  use OpenGuides::RDF::Reader;
  use WWW::Mechanize;
  ...
  my $agent = WWW::Mechanize->new;
  $agent->get("http://fooville.openguides.org/?id=Red_Lion;format=rdf");
  my %metadata = parse_rdf($agent->content);


=head1 DESCRIPTION

The L<OpenGuides> software deliberately exposes data collected on the town wiki
sites, making it available to other websites as RDF / XML. This functionality is
provided by the module L<OpenGuides::RDF> supplied in the OpenGuides distribution.

What OpenGuides::RDF::Reader does is the reverse process, i.e. take XML RDF data
and turn it back into a hash with keys comprising the metadata fields in OpenGuides.
The main use of this is for guide replication. 

=head2 parse_rdf

This exported subroutine takes a string containing RDF and returns a list of
metadata key value pairs.

=head1 BUGS

Please report any bugs in this module using http://rt.cpan.org/ or posting to
bugs-openguides-rdf-reader (at) rt.cpan.org.

=head1 SUPPORT

For discussion of all matters relating to OpenGuides, there is a mailing list
http://openguides.org/mm/listinfo/openguides-dev.

=head1 AUTHOR

	Ivor Williams
	CPAN ID: IVORW
	 
	ivorw-openguides (at) xemaps.com
	http://openguides.org/

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<OpenGuides>.

=cut


1;
# The preceding line will help the module return a true value

