package SVG::DOM2::Element::MetaData::RDF;

use base "XML::DOM2::Element";

sub new
{
	my ($proto, %args) = @_;
	return $proto->SUPER::new('rdf', %args);
}

return 1;
