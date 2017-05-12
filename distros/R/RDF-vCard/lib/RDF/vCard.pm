package RDF::vCard;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use RDF::vCard::Entity;
use RDF::vCard::Exporter;
use RDF::vCard::Importer;

our $VERSION = '0.012';

our $WITH_XML;
BEGIN {
	local $@ = undef;
	eval 'use RDF::vCard::Entity::WithXmlSupport;';
	$WITH_XML = !$@;
}

sub new_entity
{
	my ($class, @params) = @_;
	$class .= ($WITH_XML ? '::Entity::WithXmlSupport' : '::Entity');
	return $class->new(@params);
}

1;

__END__

=head1 NAME

RDF::vCard - convert between RDF and vCard

=head1 SYNOPSIS

 use RDF::vCard;
 use RDF::TrineShortcuts qw(rdf_string);
 
 my $input    = "http://example.com/contact-data.rdf";
 my $exporter = RDF::vCard::Exporter->new;
 
 my $data     = join '', $exporter->export_cards($input);
 print $data; # vCard 3.0 data
 
 my $importer = RDF::vCard::Importer->new;
 $importer->import_string($data);
 print rdf_string($importer->model => 'RDFXML');

=head1 DESCRIPTION

This module doesn't do anything itself; it just loads RDF::vCard::Exporter 
and RDF::vCard::Importer for you.

=head2 RDF::vCard::Exporter

L<RDF::vCard::Exporter> takes some RDF using the W3C's vCard vocabulary,
and outputs L<RDF::vCard::Entity> objects.

=head2 RDF::vCard::Importer

L<RDF::vCard::Importer> does the reverse.

=head2 RDF::vCard::Entity

An L<RDF::vCard::Entity> objects is an individual vCard. It overloads
stringification, so just treat it like a string.

=head2 RDF::vCard::Entity::WithXmlSupport

L<RDF::vCard::Entity::WithXmlSupport> is a subclass of L<RDF::vCard::Entity>,
with a C<to_xml> method. It requires L<XML::LibXML> to be installed and
working. The importer and exporter will try to create these if possible.

=head2 RDF::vCard::Line

L<RDF::vCard::Line> is internal fu that you probably don't want to touch.

=head1 BUGS

If your RDF asserts that Alice is Bob's AGENT and Bob is Alice's AGENT, then
L<RDF::vCard::Export> will eat your face. Don't do it.

Please report any other bugs to
L<https://rt.cpan.org/Public/Dist/Display.html?Name=RDF-vCard>.

=head1 SEE ALSO

L<http://www.w3.org/Submission/vcard-rdf/>.

L<http://perlrdf.org/>.

L<RDF::vCard::Babelfish>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

