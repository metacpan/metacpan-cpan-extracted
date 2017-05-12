#-----------------------------------------------------------------
# OWL::Data::OWL::DatatypeProperty
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: DatatypeProperty.pm,v 1.5 2009-11-12 21:11:30 ubuntu Exp $
#-----------------------------------------------------------------
package OWL::Data::OWL::DatatypeProperty;
use base ("OWL::Base");
use strict;

# imports
use RDF::Core::Resource;
use RDF::Core::Statement;
use RDF::Core::Literal;
use RDF::Core::NodeFactory;

use OWL::RDF::Predicates::DC_PROTEGE;
use OWL::RDF::Predicates::OMG_LSID;
use OWL::RDF::Predicates::OWL;
use OWL::RDF::Predicates::RDF;
use OWL::RDF::Predicates::RDFS;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

OWL::Data::OWL::DatatypeProperty

=head1 SYNOPSIS

 use OWL::Data::OWL::DatatypeProperty;

 # create an owl DatatypeProperty
 my $data = OWL::Data::OWL::DatatypeProperty->new ();


=head1 DESCRIPTION

An object representing an OWL DatatypeProperty

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See OWL::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<OWL::Base>. Here just a list of them:

=over

=item B<value> - the value that this datatype property assumes

=item B<range> - the range of this datatype property

=item B<domain> - the domain for this datatype property

=item B<uri> - the uri of this datatype property

=back

=cut

=head1 subroutines

=cut

{
	my %_allowed = (
		value  => { 
			type => OWL::Base->STRING,
		},
		range   => { type => OWL::Base->STRING },
		domain  => { type => OWL::Base->STRING },
		uri     => { type => OWL::Base->STRING },
	);

	sub _accessible {
		my ( $self, $attr ) = @_;
		exists $_allowed{$attr} or $self->SUPER::_accessible($attr);
	}

	sub _attr_prop {
		my ( $self, $attr_name, $prop_name ) = @_;
		my $attr = $_allowed{$attr_name};
		return ref($attr) ? $attr->{$prop_name} : $attr if $attr;
		return $self->SUPER::_attr_prop( $attr_name, $prop_name );
	}
}

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
	my ($self) = shift;
	$self->SUPER::init();
}

1;
__END__
